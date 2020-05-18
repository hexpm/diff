defmodule Diff.Hex.ChunkExtractor do
  @enforce_keys [:file_path, :from_line, :lines_to_read, :direction]
  defstruct Enum.map(@enforce_keys, &{&1, nil}) ++
              [
                errors: [],
                raw: nil,
                parsed: nil
              ]

  def run(params) do
    __MODULE__
    |> struct!(params)
    |> parse_integers([:from_line, :lines_to_read])
    |> validate_direction()
    |> system_read_raw_chunk()
    |> parse_chunk()
    |> remove_trailing_newline()
  end

  defp parse_integers(chunk, fields) do
    Enum.reduce(fields, chunk, &parse_integer/2)
  end

  defp parse_integer(field, chunk) do
    value = chunk |> Map.get(field) |> parse_value()

    case value do
      :error -> %{chunk | errors: {:parse_integer, "#{field} must be a number"}}
      integer -> Map.put(chunk, field, integer)
    end
  end

  defp parse_value(number) when is_integer(number), do: number

  defp parse_value(number) when is_binary(number) do
    with {int, _} <- Integer.parse(number), do: int
  end

  defp validate_direction(%{direction: direction} = chunk) when direction in ["up", "down"] do
    chunk
  end

  defp validate_direction(chunk) do
    error = {:direction, "direction must be either \"up\" or \"down\""}
    %{chunk | errors: [error | chunk.errors]}
  end

  defp system_read_raw_chunk(%{errors: [_ | _]} = chunk), do: chunk

  defp system_read_raw_chunk(chunk) do
    chunk_sh = Application.app_dir(:diff, ["priv", "chunk.sh"])

    path = chunk.file_path
    from_line = to_string(chunk.from_line)
    lines_to_read = to_string(chunk.lines_to_read)
    direction = chunk.direction

    case System.cmd(chunk_sh, [path, from_line, lines_to_read, direction], stderr_to_stdout: true) do
      {raw_chunk, 0} ->
        %{chunk | raw: raw_chunk}

      {error, code} ->
        error = {:system, "System command exited with a non-zero status #{code}: #{error}"}
        %{chunk | errors: [error | chunk.errors]}
    end
  end

  defp parse_chunk(%{errors: [_ | _]} = chunk), do: chunk

  defp parse_chunk(chunk) do
    parsed =
      chunk.raw
      |> String.split("\n")
      |> Enum.map(fn line -> %{line_text: line} end)

    set_line_numbers(%{chunk | parsed: parsed})
  end

  defp set_line_numbers(%{direction: "down"} = chunk) do
    %{chunk | parsed: parsed_with_line_numbers(chunk.parsed, chunk.from_line)}
  end

  defp set_line_numbers(%{direction: "up"} = chunk) do
    offset = chunk.from_line - length(chunk.parsed) + 1

    %{chunk | parsed: parsed_with_line_numbers(chunk.parsed, offset)}
  end

  defp parsed_with_line_numbers(parsed_chunk, starting_number) when is_binary(starting_number) do
    parsed_with_line_numbers(parsed_chunk, starting_number)
  end

  defp parsed_with_line_numbers(parsed_chunk, starting_number) do
    parsed_chunk
    |> Enum.with_index(starting_number)
    |> Enum.map(fn {line, line_number} -> Map.put_new(line, :line_number, line_number) end)
  end

  defp remove_trailing_newline(%{errors: [_ | _]} = chunk), do: {:error, chunk}

  defp remove_trailing_newline(chunk) do
    [trailing_line | reversed_tail] = Enum.reverse(chunk.parsed)

    chunk =
      case trailing_line do
        %{line_text: ""} -> %{chunk | parsed: Enum.reverse(reversed_tail)}
        %{line_text: _text} -> chunk
      end

    {:ok, chunk}
  end
end
