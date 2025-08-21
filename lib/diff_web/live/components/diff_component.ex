defmodule DiffWeb.DiffComponent do
  use DiffWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="ghd-file">
      <div class="ghd-file-header">
        <span class={"ghd-file-status ghd-file-status-#{diff_status(@diff)}"}>
          <%= diff_status(@diff) %>
        </span>
        <%= file_header(@diff, diff_status(@diff)) %>
        <span class="collapse-diff"><svg xmlns="http://www.w3.org/2000/svg" width="10" height="16" viewBox="0 0 10 16"><path fill-rule="evenodd" d="M10 10l-1.5 1.5L5 7.75 1.5 11.5 0 10l5-5 5 5z"/></svg></span>
        <span class="reveal-diff"><svg xmlns="http://www.w3.org/2000/svg" width="10" height="16" viewBox="0 0 10 16"><path fill-rule="evenodd" d="M5 11L0 6l1.5-1.5L5 8.25 8.5 4.5 10 6l-5 5z"/></svg></span>
      </div>
      <div class="ghd-diff">
        <table class="ghd-diff">
          <%= for chunk <- @diff.chunks do %>
            <tr class="ghd-chunk-header">
              <td class="ghd-line-number">
                <div class="ghd-line-number-from">&nbsp;</div>
                <div class="ghd-line-number-to"></div>
              </td>
              <td class="ghd-text">
                <div class="ghd-text-internal"><%= chunk.header %></div>
              </td>
            </tr>
            <%= for line <- chunk.lines do %>
              <tr id={line_id(@diff, line)} class={"ghd-line ghd-line-type-#{line_type(line)}"}>
                <td class="ghd-line-number">
                  <div class="ghd-line-number-from">
                    <%= line_number(line.from_line_number) %>
                  </div>
                  <div class="ghd-line-number-to">
                    <%= line_number(line.to_line_number) %>
                  </div>
                </td>
                <td class="ghd-text">
                  <div class="ghd-text-user"><%= line_text(line.text) %></div>
                </td>
              </tr>
            <% end %>
          <% end %>
        </table>
      </div>
    </div>
    """
  end

  defp file_header(diff, status) do
    from = diff.from
    to = diff.to

    case status do
      "changed" -> from
      "renamed" -> "#{from} -> #{to}"
      "removed" -> from
      "added" -> to
    end
  end

  defp diff_status(diff) do
    from = diff.from
    to = diff.to

    cond do
      !from -> "added"
      !to -> "removed"
      from == to -> "changed"
      true -> "renamed"
    end
  end

  defp line_number(ln) when is_nil(ln), do: ""
  defp line_number(ln), do: to_string(ln)

  defp line_id(diff, line) do
    hash = :erlang.phash2({diff.from, diff.to})
    ln = "-#{line.from_line_number}-#{line.to_line_number}"
    "#{hash}#{ln}"
  end

  defp line_type(line), do: to_string(line.type)

  defp line_text("+" <> text),
    do: [content_tag(:span, "+ ", class: "ghd-line-status"), content_tag(:span, text)]

  defp line_text("-" <> text),
    do: [content_tag(:span, "- ", class: "ghd-line-status"), content_tag(:span, text)]

  defp line_text(" " <> text),
    do: [content_tag(:span, "  ", class: "ghd-line-status"), content_tag(:span, text)]

  defp line_text(text), do: [content_tag(:span, text)]
end
