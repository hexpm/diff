defmodule Diff.Hex.ChunkExtractor do
  @enforce_keys [:file_path, :from_line, :to_line, :right_line]
  defstruct Enum.map(@enforce_keys, &{&1, nil}) ++ [errors: [], raw: nil, parsed: nil]

  def run(params) do
    params
    |> cast()
    |> parse_integers([:right_line, :from_line, :to_line])
    |> normalize([:from_line, :right_line])
    |> validate_to_line()
    |> system_read_raw_chunk()
    |> parse_chunk()
    |> case do
      %{errors: []} = chunk -> {:ok, chunk}
      %{errors: _} = chunk -> {:error, chunk}
    end
  end

  defp cast(params) do
    struct_keys =
      struct(__MODULE__)
      |> Map.from_struct()
      |> Enum.map(fn {key, _val} -> key end)

    struct!(__MODULE__, Map.take(params, struct_keys))
  end

  defp parse_integers(chunk, fields) do
    Enum.reduce(fields, chunk, &parse_integer/2)
  end

  defp parse_integer(field, chunk) do
    value = chunk |> Map.get(field) |> parse_value()

    case value do
      :error -> %{chunk | errors: [{:parse_integer, "#{field} must be a number"} | chunk.errors]}
      integer -> Map.put(chunk, field, integer)
    end
  end

  defp parse_value(number) when is_integer(number), do: number

  defp parse_value(number) when is_binary(number) do
    with {int, _} <- Integer.parse(number), do: int
  end

  defp normalize(%{errors: [_ | _]} = chunk, _), do: chunk

  defp normalize(chunk, fields) do
    Enum.reduce(fields, chunk, &normalize_field/2)
  end

  defp normalize_field(field, chunk) do
    case Map.fetch!(chunk, field) do
      value when value > 0 -> chunk
      _ -> Map.put(chunk, field, 1)
    end
  end

  defp validate_to_line(%{errors: [_ | _]} = chunk), do: chunk

  defp validate_to_line(%{from_line: from_line, to_line: to_line} = chunk)
       when from_line < to_line do
    chunk
  end

  defp validate_to_line(chunk) do
    error = {:param, "from_line parameter must be less than to_line"}
    %{chunk | errors: [error | chunk.errors]}
  end

  defp system_read_raw_chunk(%{errors: [_ | _]} = chunk), do: chunk

  defp system_read_raw_chunk(chunk) do
    path = chunk.file_path
    from_line = to_string(chunk.from_line)
    to_line = to_string(chunk.to_line)

    case System.cmd("sed", ["-n", "#{from_line},#{to_line}p", path], stderr_to_stdout: true) do
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
      |> remove_trailing_newline()
      |> Enum.with_index(chunk.from_line)
      |> Enum.with_index(chunk.right_line)
      # prepend line with whitespace to compensate the space introduced by leading + and - in diffs
      |> Enum.map(fn {{line, from}, to} ->
        %{text: " " <> line, from_line_number: from, to_line_number: to}
      end)

    %{chunk | parsed: parsed}
  end

  defp remove_trailing_newline(lines) do
    lines
    |> Enum.reverse()
    |> tl()
    |> Enum.reverse()
  end
end
