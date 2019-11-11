defmodule Diff.Render do
  import Phoenix.HTML
  def file_header(patch, status) do
    from = patch.from
    to = patch.to

    case status do
      "changed" -> from
      "renamed" -> "#{from} -> #{to}"
      "removed" -> from
      "added" -> to
    end
  end

  def patch_status(patch) do
    from = patch.from
    to = patch.to

    cond do
      !from -> "added"
      !to -> "removed"
      from == to -> "changed"
      true -> "renamed"
    end
  end

  def line_number(ln) when is_nil(ln), do: ""
  def line_number(ln), do: to_string(ln)

  def line_id(patch, line) do
    hash = :erlang.phash2({patch.from, patch.to})

    ln = line.from_line_number || line.to_line_number

    [to_string(hash), to_string(ln)]
  end

  def line_type(line), do: to_string(line.type)


  def diff_to_html(diff) do
    html = ~E"""
    <div class="ghd-container">
      <%= for patch <- diff do %>
        <% status = patch_status(patch) %>
        <div class="ghd-file">
          <div class="ghd-file-header">
            <span class="ghd-file-status ghd-file-status-<%= status %>">
              <%= status %>
            </span>
            <%= file_header(patch, status) %>
          </div>
          <div class="ghd-diff">
            <table class="ghd-diff">
              <%= for chunk <- patch.chunks do %>
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
                  <tr id="<%= line_id(patch, line) %>" class="ghd-line ghd-line-type-<%= line_type(line) %>">
                    <td class="ghd-line-number">
                      <div class="ghd-line-number-from">
                        <%= line_number(line.from_line_number) %>
                      </div>
                      <div class="ghd-line-number-to">
                        <%= line_number(line.to_line_number) %>
                      </div>
                    </td>
                    <td class="ghd-text">
                      <div class="ghd-text-internal"><%= line.text %></div>
                    </td>
                  </tr>
                <% end %>
              <% end %>
            </table>
          </div>
        </div>
      <% end %>
    </div>
    """

    Phoenix.HTML.Engine.encode_to_iodata!(html)
  end
end
