defmodule DiffWeb.DiffLiveView do
  use DiffWeb, :live_view

  require Logger

  def render(assigns) do
    Phoenix.View.render(DiffWeb.LiveView, "diff.html", assigns)
  end

  # Mount for single diff view
  def mount(%{"package" => package, "versions" => versions}, _session, socket) do
    case parse_versions(versions) do
      {:ok, from, to} ->
        case resolve_latest_version(package, from, to) do
          {:ok, resolved_from, resolved_to} ->
            mount_single_diff(socket, package, resolved_from, resolved_to)

          {:error, reason} ->
            {:ok, assign(socket, error: "Package not found: #{reason}")}
        end

      :error ->
        {:ok, assign(socket, error: "Invalid version format")}
    end
  end

  # Mount for diffs list view
  def mount(%{"diffs" => raw_diffs}, _session, socket) when is_list(raw_diffs) do
    diffs =
      raw_diffs
      |> Enum.map(&parse_diff/1)
      |> Enum.reject(&is_nil/1)

    socket =
      assign(socket,
        view_mode: :diffs_list,
        diffs: diffs
      )

    {:ok, socket}
  end

  def mount(params, _session, socket) do
    case Map.get(params, "diffs") do
      nil ->
        {:ok, assign(socket, view_mode: :diffs_list, diffs: [], error: "No diffs provided")}

      [] ->
        {:ok, assign(socket, view_mode: :diffs_list, diffs: [], error: "No diffs provided")}

      diffs_param ->
        mount(%{"diffs" => List.wrap(diffs_param)}, nil, socket)
    end
  end

  defp mount_single_diff(socket, package, from, to) do
    case Diff.Storage.get_metadata(package, from, to) do
      {:ok, metadata} ->
        load_existing_diff(socket, package, from, to, metadata)

      {:error, :not_found} ->
        generate_new_diff(socket, package, from, to)

      {:error, reason} ->
        Logger.error("Failed to load diff metadata: #{inspect(reason)}")
        {:ok, assign(socket, error: "Failed to load diff")}
    end
  end

  defp load_existing_diff(socket, package, from, to, metadata) do
    {:ok, diff_ids} = Diff.Storage.list_diffs(package, from, to)

    initial_batch_size = 5
    {initial_diffs, remaining} = Enum.split(diff_ids, initial_batch_size)

    socket =
      assign(socket,
        view_mode: :single_diff,
        package: package,
        from: from,
        to: to,
        metadata: metadata,
        all_diff_ids: diff_ids,
        loaded_diffs: initial_diffs,
        loaded_diff_content: %{},
        remaining_diffs: remaining,
        loading: true,
        generating: false,
        has_more_diffs: length(remaining) > 0
      )

    send(self(), {:load_diffs, initial_diffs})

    {:ok, socket}
  end

  defp generate_new_diff(socket, package, from, to) do
    socket =
      assign(socket,
        view_mode: :single_diff,
        package: package,
        from: from,
        to: to,
        metadata: %{files_changed: 0, total_additions: 0, total_deletions: 0},
        all_diff_ids: [],
        loaded_diffs: [],
        loaded_diff_content: %{},
        remaining_diffs: [],
        loading: false,
        generating: true,
        has_more_diffs: false
      )

    send(self(), {:generate_diff, package, from, to})

    {:ok, socket}
  end

  defp resolve_latest_version(package, from, to) when to == :latest or to == "latest" do
    case Diff.Package.Store.get_versions(package) do
      {:ok, versions} ->
        to =
          versions
          |> Enum.map(&Version.parse!/1)
          |> Enum.filter(&(&1.pre == []))
          |> Enum.max(Version)

        {:ok, from, to_string(to)}

      {:error, :not_found} ->
        {:error, :not_found}
    end
  end

  defp resolve_latest_version(_package, from, to), do: {:ok, from, to}

  def handle_event("load-more", _params, socket) do
    batch_size = 5
    {next_batch, remaining} = Enum.split(socket.assigns.remaining_diffs, batch_size)

    socket =
      socket
      |> assign(
        remaining_diffs: remaining,
        has_more_diffs: length(remaining) > 0
      )

    send(self(), {:load_diffs_and_update, next_batch})

    {:noreply, socket}
  end

  def handle_info({:generate_diff, package, from, to}, socket) do
    hex_impl = Application.get_env(:diff, :hex_impl, Diff.Hex)

    case hex_impl.diff(package, from, to) do
      {:ok, stream} ->
        case process_stream_to_diffs(package, from, to, stream) do
          {:ok, metadata, diff_ids} ->
            initial_batch_size = 5
            {initial_diffs, remaining} = Enum.split(diff_ids, initial_batch_size)

            socket =
              socket
              |> assign(
                metadata: metadata,
                all_diff_ids: diff_ids,
                loaded_diffs: initial_diffs,
                loaded_diff_content: %{},
                remaining_diffs: remaining,
                generating: false,
                loading: true,
                has_more_diffs: length(remaining) > 0
              )

            send(self(), {:load_diffs, initial_diffs})

            {:noreply, socket}

          {:error, reason} ->
            Logger.error("Failed to generate diff: #{inspect(reason)}")
            {:noreply, assign(socket, error: "Failed to generate diff", generating: false)}
        end

      :error ->
        {:noreply, assign(socket, error: "Failed to generate diff", generating: false)}
    end
  catch
    :throw, {:diff, :invalid_diff} ->
      {:noreply, assign(socket, error: "Invalid diff", generating: false)}
  end

  def handle_info({:load_diffs_and_update, diff_ids}, socket) do
    # Load diffs in parallel and add to existing loaded content
    new_loaded_content =
      load_diffs_in_parallel(
        socket.assigns.package,
        socket.assigns.from,
        socket.assigns.to,
        diff_ids
      )

    existing_content = Map.get(socket.assigns, :loaded_diff_content, %{})
    all_loaded_content = Map.merge(existing_content, new_loaded_content)

    new_loaded_diffs = socket.assigns.loaded_diffs ++ diff_ids

    socket =
      socket
      |> assign(
        loaded_diffs: new_loaded_diffs,
        loaded_diff_content: all_loaded_content,
        loading: false
      )

    {:noreply, socket}
  end

  def handle_info({:load_diffs, diff_ids}, socket) do
    # Load initial diffs in parallel
    loaded_content =
      load_diffs_in_parallel(
        socket.assigns.package,
        socket.assigns.from,
        socket.assigns.to,
        diff_ids
      )

    socket =
      socket
      |> assign(
        loaded_diff_content: loaded_content,
        loading: false
      )

    {:noreply, socket}
  end

  defp process_stream_to_diffs(package, from, to, stream) do
    initial_metadata = %{
      total_diffs: 0,
      total_additions: 0,
      total_deletions: 0,
      files_changed: 0
    }

    # Process stream elements in parallel with indices
    indexed_stream = Stream.with_index(stream)

    results =
      Task.Supervisor.async_stream(
        Diff.Tasks,
        indexed_stream,
        fn {element, index} ->
          process_stream_element(package, from, to, element, index)
        end,
        max_concurrency: 10,
        timeout: 30_000,
        ordered: true
      )
      |> Enum.reduce({initial_metadata, []}, fn
        {:ok, {:ok, diff_id, metadata_update}}, {acc_metadata, acc_diff_ids} ->
          updated_metadata = merge_metadata(acc_metadata, metadata_update)
          {updated_metadata, acc_diff_ids ++ [diff_id]}

        {:ok, {:error, _}}, acc ->
          acc

        {:error, _}, acc ->
          acc
      end)

    case results do
      {final_metadata, diff_ids} ->
        case Diff.Storage.put_metadata(package, from, to, final_metadata) do
          :ok ->
            {:ok, final_metadata, diff_ids}

          {:error, reason} ->
            Logger.error("Failed to store metadata: #{inspect(reason)}")
            {:error, reason}
        end
    end
  catch
    :throw, {:diff, :invalid_diff} ->
      {:error, :invalid_diff}
  end

  defp process_stream_element(package, from, to, element, index) do
    case element do
      {:ok, {raw_diff, path_from, path_to}} ->
        diff_id = "diff-#{index}"

        diff_data =
          Jason.encode!(%{
            "diff" => DiffWeb.LiveView.sanitize_utf8(raw_diff),
            "path_from" => path_from,
            "path_to" => path_to
          })

        case Diff.Storage.put_diff(package, from, to, diff_id, diff_data) do
          :ok ->
            # Count additions and deletions from raw diff (exclude +++ and --- headers)
            lines = String.split(raw_diff, "\n")

            additions =
              Enum.count(lines, fn line ->
                String.starts_with?(line, "+") and not String.starts_with?(line, "+++")
              end)

            deletions =
              Enum.count(lines, fn line ->
                String.starts_with?(line, "-") and not String.starts_with?(line, "---")
              end)

            metadata_update = %{
              total_diffs: 1,
              total_additions: additions,
              total_deletions: deletions,
              files_changed: 1
            }

            {:ok, diff_id, metadata_update}

          {:error, reason} ->
            Logger.error("Failed to store diff #{diff_id}: #{inspect(reason)}")
            {:error, reason}
        end

      {:too_large, file_path} ->
        diff_id = "diff-#{index}"
        too_large_data = Jason.encode!(%{type: "too_large", file: file_path})

        case Diff.Storage.put_diff(package, from, to, diff_id, too_large_data) do
          :ok ->
            metadata_update = %{
              total_diffs: 1,
              total_additions: 0,
              total_deletions: 0,
              files_changed: 1
            }

            {:ok, diff_id, metadata_update}

          {:error, reason} ->
            Logger.error("Failed to store too_large diff #{diff_id}: #{inspect(reason)}")
            {:error, reason}
        end

      {:error, error} ->
        Logger.error(
          "Failed to process diff #{index} for #{package} #{from}..#{to} with: #{inspect(error)}"
        )

        {:error, error}
    end
  end

  defp merge_metadata(acc_metadata, update) do
    %{
      total_diffs: acc_metadata.total_diffs + update.total_diffs,
      total_additions: acc_metadata.total_additions + update.total_additions,
      total_deletions: acc_metadata.total_deletions + update.total_deletions,
      files_changed: acc_metadata.files_changed + update.files_changed
    }
  end

  defp parse_versions(input) do
    with {:ok, [from, to]} <- versions_from_input(input),
         {:ok, from} <- parse_version(from),
         {:ok, to} <- parse_version(to) do
      {:ok, to_string(from), to_string(to)}
    else
      _ ->
        :error
    end
  end

  defp versions_from_input(input) when is_binary(input) do
    input
    |> String.split("..", parts: 2)
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

  defp parse_diff(diff) do
    case String.split(diff, ":", trim: true) do
      [app, from, to] -> {app, from, to, build_url(app, from, to)}
      _ -> nil
    end
  end

  defp build_url(app, from, to), do: "/diff/#{app}/#{from}..#{to}"

  defp load_diffs_in_parallel(package, from, to, diff_ids) do
    Task.Supervisor.async_stream(
      Diff.Tasks,
      diff_ids,
      fn diff_id ->
        {diff_id, DiffWeb.LiveView.load_diff_content(package, from, to, diff_id)}
      end,
      max_concurrency: 10,
      timeout: 30_000
    )
    |> Enum.reduce(%{}, fn
      {:ok, {diff_id, content}}, acc -> Map.put(acc, diff_id, content)
      {:error, _}, acc -> acc
    end)
  end
end
