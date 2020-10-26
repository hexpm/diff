defmodule Diff.Hex do
  @config %{
    :hex_core.default_config()
    | http_adapter: Diff.Hex.Adapter,
      http_user_agent_fragment: "hexpm_diff"
  }

  require Logger

  def get_versions() do
    with {:ok, {200, _, results}} <- :hex_repo.get_versions(@config) do
      {:ok, results}
    else
      {:ok, {status, _, _}} ->
        Logger.error("Failed to get package versions. Status: #{status}.")
        {:error, :not_found}

      {:error, reason} ->
        Logger.error("Failed to get package versions. Reason: #{inspect(reason)}.")
        {:error, :not_found}
    end
  end

  def get_tarball(package, version) do
    with {:ok, {200, _, tarball}} <- :hex_repo.get_tarball(@config, package, version) do
      {:ok, tarball}
    else
      {:ok, {403, _, _}} ->
        {:error, :not_found}

      {:ok, {status, _, _}} ->
        Logger.error("Failed to get package versions. Status: #{status}.")
        {:error, :not_found}

      {:error, reason} ->
        Logger.error("Failed to get tarball for package: #{package}. Reason: #{inspect(reason)}.")
        {:error, :not_found}
    end
  end

  def unpack_tarball(tarball, path) when is_binary(path) do
    do_unpack_tarball(tarball, :all_files, path)
  end

  def unpack_tarball(tarball, file_list, path) when is_binary(path) do
    file_list = Enum.map(file_list, &to_charlist/1)
    do_unpack_tarball(tarball, file_list, path)
  end

  def do_unpack_tarball(tarball, file_list, path) do
    path = to_charlist(path)

    with {:ok, _} <- :hex_tarball.unpack(tarball, file_list, path) do
      :ok
    end
  end

  def get_checksums(package, versions) do
    with {:ok, {200, _, releases}} <- :hex_repo.get_package(@config, package) do
      checksums =
        for release <- releases, release.version in versions do
          release.outer_checksum
        end

      {:ok, checksums}
    else
      {:ok, {status, _, _}} ->
        Logger.error("Failed to get checksums for package: #{package}. Status: #{status}.")
        {:error, :not_found}

      {:error, reason} ->
        Logger.error(
          "Failed to get checksums for package: #{package}. Reason: #{inspect(reason)}"
        )

        {:error, :not_found}
    end
  end

  def diff(package, from, to) do
    path_from = tmp_path("package-#{package}-#{from}-")
    path_to = tmp_path("package-#{package}-#{to}-")
    path_diff = tmp_path("diff-#{package}-#{from}-#{to}-")

    try do
      with {:ok, tarball_from} <- get_tarball(package, from),
           :ok <- unpack_tarball(tarball_from, path_from),
           {:ok, tarball_to} <- get_tarball(package, to),
           :ok <- unpack_tarball(tarball_to, path_to),
           :ok <- git_diff(path_from, path_to, path_diff) do
        stream =
          File.stream!(path_diff, [:read_ahead])
          |> GitDiff.stream_patch(relative_from: path_from, relative_to: path_to)
          |> Stream.transform(
            fn -> :ok end,
            fn elem, :ok -> {[elem], :ok} end,
            fn :ok -> File.rm(path_diff) end
          )

        {:ok, stream}
      else
        error ->
          Logger.error("Failed to create diff #{package} #{from}..#{to} with: #{inspect(error)}")
          :error
      end
    after
      File.rm_rf(path_from)
      File.rm_rf(path_to)
    end
  end

  def get_chunk(params) do
    path = tmp_path("chunk")

    chunk_extractor_params = Map.put(params, :file_path, Path.join(path, params.file_name))

    try do
      with {:ok, tarball} <- get_tarball(params.package, params.version),
           :ok <- unpack_tarball(tarball, [params.file_name], path),
           {:ok, %{parsed: parsed_chunk}} <- Diff.Hex.ChunkExtractor.run(chunk_extractor_params) do
        {:ok, parsed_chunk}
      else
        {:error, %Diff.Hex.ChunkExtractor{errors: errors} = chunk} ->
          Logger.error(inspect(errors))
          {:error, chunk}

        error ->
          Logger.error(inspect(error))
          {:error, error}
      end
    after
      File.rm_rf(path)
    end
  end

  defp git_diff(path_from, path_to, path_out) do
    case System.cmd("git", [
           "-c",
           "core.quotepath=false",
           "-c",
           "diff.algorithm=histogram",
           "diff",
           "--no-index",
           "--no-color",
           "--output=#{path_out}",
           path_from,
           path_to
         ]) do
      {"", 1} ->
        :ok

      other ->
        {:error, other}
    end
  end

  defp tmp_path(prefix) do
    random_string = Base.encode16(:crypto.strong_rand_bytes(4))
    Path.join([System.tmp_dir!(), "diff", prefix <> random_string])
  end
end
