defmodule DiffWeb.SearchView do
  use Phoenix.LiveView

  def render(assigns) do
    ~L"""
    <div class="search-area">
      <form phx-change="search" phx-submit="go" class="search-form">
        <input
          autocomplete="off"
          autofocus
          class="search-input"
          type="text"
          name="q"
          value="<%= @query %>"
          placeholder="Search..."
        />
        <div class="suggestions">
          <%= if length(@suggestions) > 0 do %>
            Did you mean:
            <%= for suggestion <- @suggestions do %>
              <span class="suggestion" phx-click="search_<%= suggestion %>"><%= suggestion %></span>
            <% end %>
          <% end %>
        </div>
      </form>
      <%= if length(@releases) == 1 do %>
        The package only has one version so there's nothing to diff with.
      <% else %>
        <%= if @result do %>
          <form phx-change="diff" class="version-form">
            <div style="display: flex; flex-direction: column">
              <div class="select-area">
                <label for="from">From</label>
                <select name="from">
                  <%= for release_from <- @from_releases do %>
                    <option <%= selected(@from, release_from) %> value="<%= release_from %>"><%= release_from %></option>
                  <% end %>
                </select>
                <label for="to">To</label>
                <select name="to">
                  <%= for release_to <- @to_releases do %>
                    <option <%= selected(@to, release_to) %> value="<%= release_to %>"><%= release_to %></option>
                  <% end %>
                </select>
              </div>
              <button
                type="button"
                <%= disabled([@from, @to]) %>
                phx-click="go"
              >Diff</button>
              </a>
            </div>
          </form>
        <% end %>
      <% end %>
      <%= @not_found %>
    </div>
    """
  end

  def mount(_session, socket) do
    {:ok, reset_state(socket)}
  end

  def handle_event("search", %{"q" => ""}, socket), do: {:noreply, reset_state(socket)}

  def handle_event("search", %{"q" => query}, socket) when byte_size(query) <= 30 do
    send(self(), {:search, query})
    {:noreply, assign(socket, query: query)}
  end

  def handle_event("search_" <> suggestion, _params, socket) do
    send(self(), {:search, suggestion})
    {:noreply, assign(socket, query: suggestion)}
  end

  def handle_event(
        "diff",
        %{"_target" => ["from"]} = data,
        %{assigns: %{releases: releases}} = socket
      ) do
    from = Map.get(data, "from")

    index_of_selected_from = Enum.find_index(releases, &(&1 == from))
    to_releases = Enum.slice(releases, (index_of_selected_from + 1)..-1)
    to = List.last(to_releases)

    {:noreply,
     assign(socket,
       from: from,
       to: to,
       to_releases: to_releases
     )}
  end

  def handle_event(
        "diff",
        %{"_target" => ["to"]} = data,
        socket
      ) do
    to = Map.get(data, "to")

    {:noreply,
     assign(socket,
       to: to
     )}
  end

  def handle_event("go", _params, %{assigns: %{result: result, to: to, from: from}} = socket)
      when is_binary(result) and is_binary(from) and is_binary(to) do
    {:stop, redirect(socket, to: build_url(result, from, to))}
  end

  def handle_event("go", _params, socket) do
    {:noreply, socket}
  end

  def handle_info({:search, query}, socket) do
    suggestions = get_suggestions(query)

    case Diff.Package.Store.get_versions(query) do
      {:ok, versions} ->
        from_releases = Enum.slice(versions, 0..(length(versions) - 2))
        to_releases = Enum.slice(versions, -1..-1)
        from = List.last(from_releases)
        to = List.last(to_releases)

        {:noreply,
         assign(socket,
           result: query,
           query: query,
           releases: versions,
           from_releases: from_releases,
           to_releases: to_releases,
           to: to,
           from: from,
           suggestions: suggestions,
           not_found: nil
         )}

      {:error, :not_found} ->
        {:noreply,
         assign(socket,
           result: nil,
           not_found: "Package #{query} not found.",
           suggestions: suggestions,
           to: nil,
           from: nil
         )}
    end
  end

  defp reset_state(socket) do
    assign(socket,
      query: nil,
      result: nil,
      matches: [],
      releases: [],
      from: nil,
      to: nil,
      from_releases: [],
      to_releases: [],
      not_found: nil,
      suggestions: []
    )
  end

  defp build_url(app, from, to), do: "/diff/#{app}/#{from}/#{to}"

  defp disabled(things) when is_list(things) do
    if Enum.any?(things, &(!&1)) do
      "disabled"
    else
      ""
    end
  end

  defp disabled(thing), do: disabled([thing])

  defp selected(x, x), do: "selected=\"selected\""
  defp selected(_, _), do: ""

  def get_suggestions(query) do
    names = Diff.Package.Store.get_names()

    starts =
      names
      |> Enum.filter(&String.starts_with?(&1, query))
      |> Enum.sort()
      |> Enum.map(&{&1})

    names
    |> Stream.map(&{&1, String.jaro_distance(query, &1)})
    |> Stream.filter(fn
      {^query, 1.0} -> false
      {_, value} -> value > 0.8
    end)
    |> Enum.sort(fn {_, v1}, {_, v2} -> v1 > v2 end)
    |> (fn items -> Enum.concat(starts, items) end).()
    |> Enum.take(3)
    |> Enum.map(&elem(&1, 0))
  end
end
