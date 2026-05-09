defmodule Diff.Storage.Local do
  require Logger

  @behaviour Diff.Storage

  def get_diff(package, from_version, to_version, diff_id, opts \\ []) do
    case combined_checksum(package, from_version, to_version, opts) do
      {:ok, hash} ->
        filename = diff_key(package, from_version, to_version, hash, diff_id)
        path = Path.join([dir(), package, filename])

        if File.regular?(path) do
          {:ok, File.read!(path)}
        else
          {:error, :not_found}
        end

      {:error, :not_found} ->
        {:error, :not_found}
    end
  end

  def put_diff(package, from_version, to_version, diff_id, diff_data, opts \\ []) do
    with {:ok, hash} <- combined_checksum(package, from_version, to_version, opts),
         filename = diff_key(package, from_version, to_version, hash, diff_id),
         path = Path.join([dir(), package, filename]),
         :ok <- File.mkdir_p(Path.dirname(path)) do
      File.write!(path, diff_data)
      :ok
    else
      {:error, reason} ->
        Logger.error("Failed to store diff. Reason: #{inspect(reason)}.")
        {:error, reason}
    end
  end

  def list_diffs(package, from_version, to_version, opts \\ []) do
    case get_metadata(package, from_version, to_version, opts) do
      {:ok, %{total_diffs: total_diffs}} ->
        diff_ids = diff_ids(total_diffs)
        {:ok, diff_ids}

      {:error, :not_found} ->
        {:ok, []}

      error ->
        error
    end
  end

  def get_metadata(package, from_version, to_version, opts \\ []) do
    case combined_checksum(package, from_version, to_version, opts) do
      {:ok, hash} ->
        filename = metadata_key(package, from_version, to_version, hash)
        path = Path.join([dir(), package, filename])

        if File.regular?(path) do
          case File.read(path) do
            {:ok, content} ->
              case Jason.decode(content, keys: :atoms) do
                {:ok, metadata} -> {:ok, metadata}
                {:error, _} -> {:error, :invalid_metadata}
              end

            {:error, reason} ->
              {:error, reason}
          end
        else
          {:error, :not_found}
        end

      {:error, :not_found} ->
        {:error, :not_found}
    end
  end

  def put_metadata(package, from_version, to_version, metadata, opts \\ []) do
    with {:ok, hash} <- combined_checksum(package, from_version, to_version, opts),
         filename = metadata_key(package, from_version, to_version, hash),
         path = Path.join([dir(), package, filename]),
         :ok <- File.mkdir_p(Path.dirname(path)),
         {:ok, json} <- Jason.encode(metadata) do
      File.write!(path, json)
      :ok
    else
      {:error, reason} ->
        Logger.error("Failed to store metadata. Reason: #{inspect(reason)}.")
        {:error, reason}
    end
  end

  def combined_checksum(package, from, to, opts \\ []) do
    with {:ok, checksums} <- Diff.Hex.get_checksums(package, [from, to]) do
      {:ok, :erlang.phash2(Diff.Storage.cache_key(checksums, opts))}
    end
  end

  defp diff_ids(0), do: []

  defp diff_ids(total_diffs) do
    0..(total_diffs - 1) |> Enum.map(&"diff-#{&1}")
  end

  defp diff_key(package, from_version, to_version, hash, diff_id) do
    "diffs/#{package}-#{from_version}-#{to_version}-#{hash}-#{diff_id}.json"
  end

  defp metadata_key(package, from_version, to_version, hash) do
    "metadata/#{package}-#{from_version}-#{to_version}-#{hash}.json"
  end

  defp dir() do
    Application.get_env(:diff, :tmp_dir)
    |> Path.join("storage")
  end
end
