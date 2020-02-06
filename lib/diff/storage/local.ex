defmodule Diff.Storage.Local do
  require Logger

  @behaviour Diff.Storage

  def get(package, from_version, to_version) do
    with {:ok, hash} <- combined_checksum(package, from_version, to_version),
         filename = key(package, from_version, to_version, hash),
         path = Path.join([dir(), package, filename]),
         {:ok, diff} <- File.read(path) do
      {:ok, diff}
    else
      {:error, :not_found} -> {:error, :not_found}
      {:error, :enoent} -> {:error, :not_found}
    end
  end

  def put(package, from_version, to_version, diff) do
    with {:ok, hash} <- combined_checksum(package, from_version, to_version),
         filename = key(package, from_version, to_version, hash),
         path = Path.join([dir(), package, filename]),
         :ok <- File.mkdir_p(Path.dirname(path)),
         :ok <- File.write(path, diff) do
      :ok
    else
      {:error, reason} ->
        Logger.error("Failed to store diff. Reason: #{inspect(reason)}.")
        {:error, reason}
    end
  end

  def combined_checksum(package, from, to) do
    with {:ok, checksums} <- Diff.Hex.get_checksums(package, [from, to]) do
      {:ok, :erlang.phash2({Application.get_env(:diff, :cache_version), checksums})}
    end
  end

  defp key(package, from_version, to_version, hash) do
    "#{package}-#{from_version}-#{to_version}-#{hash}.html"
  end

  defp dir() do
    Application.get_env(:diff, :tmp_dir)
    |> Path.join("storage")
  end
end
