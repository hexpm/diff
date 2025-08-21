defmodule DiffWeb.TooLargeComponent do
  use DiffWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="ghd-file">
      <div class="ghd-file-header">
        <span class="ghd-file-status">
          unknown
        </span>
        <%= @file %>
        <span class="collapse-diff"><svg xmlns="http://www.w3.org/2000/svg" width="10" height="16" viewBox="0 0 10 16"><path fill-rule="evenodd" d="M10 10l-1.5 1.5L5 7.75 1.5 11.5 0 10l5-5 5 5z"/></svg></span>
        <span class="reveal-diff"><svg xmlns="http://www.w3.org/2000/svg" width="10" height="16" viewBox="0 0 10 16"><path fill-rule="evenodd" d="M5 11L0 6l1.5-1.5L5 8.25 8.5 4.5 10 6l-5 5z"/></svg></span>
      </div>
      <div class="ghd-diff ghd-diff-error">
        CANNOT RENDER FILES LARGER THAN 1MB
      </div>
    </div>
    """
  end
end
