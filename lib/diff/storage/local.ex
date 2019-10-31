defmodule Diff.Storage.Local do
  @behaviour Diff.Storage

  def get(package, from_version, to_version) do
    filename = key(package, from_version, to_version)
    path = Path.join([dir(), package, filename])

    case File.read(path) do
      {:ok, diff} -> {:ok, diff}
      {:error, :enoent} -> {:error, :not_found}
    end
  end

  def put(package, from_version, to_version, diff) do
    filename = key(package, from_version, to_version)
    path = Path.join([dir(), package, filename])

    File.mkdir_p!(Path.dirname(path))

    case File.write(path, diff) do
      :ok -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp key(package, from_version, to_version) do
    "#{package}-#{from_version}-#{to_version}.tgz"
  end

  defp dir() do
    Application.get_env(:diff, :tmp_dir)
    |> Path.join("storage")
  end
end
