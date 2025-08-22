defmodule DiffWeb.LiveView do
  use DiffWeb, :view
  require Logger

  def load_diff_content(package, from, to, diff_id) do
    case Diff.Storage.get_diff(package, from, to, diff_id) do
      {:ok, raw_content} ->
        # Parse the stored content based on format
        case Jason.decode(raw_content) do
          {:ok, %{"type" => "too_large", "file" => file_path}} ->
            DiffWeb.TooLargeComponent.render(%{file: file_path})
            |> Phoenix.HTML.Safe.to_iodata()
            |> IO.iodata_to_binary()

          {:ok, %{"diff" => raw_diff, "path_from" => path_from, "path_to" => path_to}} ->
            case GitDiff.parse_patch(raw_diff, relative_from: path_from, relative_to: path_to) do
              {:ok, []} ->
                "<div class='diff-info'>No changes in diff</div>"

              {:ok, diffs} ->
                # Take the first diff (should only be one per file)
                diff = List.first(diffs)

                DiffWeb.DiffComponent.render(%{diff: diff})
                |> Phoenix.HTML.Safe.to_iodata()
                |> IO.iodata_to_binary()
                |> sanitize_utf8()

              {:error, reason} ->
                Logger.error("Failed to parse diff #{diff_id}: #{inspect(reason)}")
                "<div class='diff-error'>Failed to parse diff</div>"
            end
        end

      {:error, _reason} ->
        "<div class='diff-error'>Failed to load diff</div>"
    end
  end

  def sanitize_utf8(content) when is_binary(content) do
    content
    |> String.chunk(:valid)
    |> Enum.map(fn chunk ->
      if String.valid?(chunk) do
        chunk
      else
        String.duplicate("?", byte_size(chunk))
      end
    end)
    |> Enum.join("")
  end
end
