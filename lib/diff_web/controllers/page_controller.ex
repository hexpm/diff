defmodule DiffWeb.PageController do
  use DiffWeb, :controller

  require Logger

  @chunk_size 64 * 1024

  def diff(conn, %{"package" => package, "versions" => versions}) do
    case parse_versions(versions) do
      {:ok, from, to} ->
        maybe_cached_diff(conn, package, from, to)

      :error ->
        render_error(conn, 400)
    end
  end

  defp maybe_cached_diff(conn, _package, version, version) do
    render_error(conn, 400)
  end

  defp maybe_cached_diff(conn, _package, :latest, _version) do
    render_error(conn, 400)
  end

  defp maybe_cached_diff(conn, package, from, :latest) do
    case Diff.Package.Store.get_versions(package) do
      {:ok, versions} ->
        to =
          versions
          |> Enum.map(&Version.parse!/1)
          |> Enum.filter(&(&1.pre == []))
          |> Enum.max(Version)

        maybe_cached_diff(conn, package, from, to)

      {:error, :not_found} ->
        render_error(conn, 404)
    end
  end

  defp maybe_cached_diff(conn, package, from, to) do
    from = to_string(from)
    to = to_string(to)

    case Diff.Storage.get(package, from, to) do
      {:ok, stream} ->
        Logger.debug("cache hit for #{package}/#{from}..#{to}")

        conn
        |> put_resp_content_type("text/html")
        |> stream_diff(stream)

      {:error, :not_found} ->
        Logger.debug("cache miss for #{package}/#{from}..#{to}")
        do_diff(conn, package, from, to)
    end
  end

  defp do_diff(conn, package, from, to) do
    case Diff.Hex.diff(package, from, to) do
      {:ok, stream} ->
        path = render_diff(package, from, to, stream, conn)
        stream = File.stream!(path, [:read_ahead], @chunk_size)

        cache_diff(package, from, to, stream)
        delete_diff(path)

        conn
        |> put_resp_content_type("text/html")
        |> stream_diff(stream)

      :error ->
        render(conn, "500.html")
    end
  catch
    :throw, {:diff, :invalid_diff} ->
      render(conn, "500.html")
  end

  defp stream_diff(conn, stream) do
    header = [
      Phoenix.View.render_to_iodata(DiffWeb.LayoutView, "header.html", conn: conn),
      Phoenix.View.render_to_iodata(DiffWeb.PageView, "diff_header.html", [])
    ]

    footer = [
      Phoenix.View.render_to_iodata(DiffWeb.PageView, "diff_footer.html", []),
      Phoenix.View.render_to_iodata(DiffWeb.LayoutView, "footer.html", conn: conn)
    ]

    conn = send_chunked(conn, 200)

    with {:ok, conn} <- chunk(conn, header),
         {:ok, conn} <- stream_chunks(conn, stream),
         {:ok, conn} <- chunk(conn, footer) do
      conn
    else
      {:error, reason} ->
        Logger.error("chunking failed: #{inspect(reason)}")
        conn
    end
  end

  defp stream_chunks(conn, stream) do
    Enum.reduce_while(stream, {:ok, conn}, fn chunk, {:ok, conn} ->
      case chunk(conn, chunk) do
        {:ok, conn} ->
          {:cont, {:ok, conn}}

        {:error, reason} ->
          {:halt, {:error, reason}}
      end
    end)
  end

  defp render_diff(package, from, to, stream, conn) do
    path = tmp_path("html-#{package}-#{from}-#{to}-")

    File.open!(path, [:write, :raw, :binary, :write_delay], fn file ->
      Enum.each(stream, fn
        {:ok, patch} ->
          html_patch =
            Phoenix.View.render_to_iodata(DiffWeb.RenderView, "render.html",
              patch: patch,
              conn: conn
            )

          IO.binwrite(file, html_patch)

        {:error, error} ->
          Logger.error("Failed to parse diff #{package} #{from}..#{to} with: #{inspect(error)}")
          throw({:diff, :invalid_diff})
      end)
    end)

    path
  end

  defp cache_diff(package, from, to, stream) do
    Task.Supervisor.start_child(Diff.Tasks, fn ->
      Diff.Storage.put(package, from, to, stream)
    end)
  end

  # A bit of a hack to make sure both the GCS upload and chunked response
  # has opened file before we delete it
  defp delete_diff(path) do
    Task.Supervisor.start_child(Diff.Tasks, fn ->
      Process.sleep(10_000)
      File.rm(path)
    end)
  end

  defp parse_versions(input) do
    with {:ok, [from, to]} <- versions_from_input(input),
         {:ok, from} <- parse_version(from),
         {:ok, to} <- parse_version(to) do
      {:ok, from, to}
    else
      _ ->
        :error
    end
  end

  defp versions_from_input(input) when is_binary(input) do
    input
    |> String.split("..")
    |> case do
      [from] ->
        [from, ""]

      [from, to] ->
        [from, to]
    end
    |> versions_from_input()
  end

  defp versions_from_input([_from, _to] = versions) do
    versions = Enum.map(versions, &String.trim/1)
    {:ok, versions}
  end

  defp versions_from_input(_), do: :error

  defp parse_version(""), do: {:ok, :latest}
  defp parse_version(input), do: Version.parse(input)

  defp render_error(conn, status) do
    conn
    |> put_status(status)
    |> render("#{status}.html")
  end

  defp tmp_path(prefix) do
    random_string = Base.encode16(:crypto.strong_rand_bytes(4))
    Path.join([System.tmp_dir!(), "diff", prefix <> random_string])
  end
end
