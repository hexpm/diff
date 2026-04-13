defmodule DiffWeb.SearchLiveView do
  use DiffWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="flex-1 flex flex-col items-center w-full py-16 px-4">
      <h1 class="text-h5 font-bold text-grey-800 mb-2">Package Diffs</h1>
      <p class="text-grey-400 text-sm mb-8">Compare any two versions of a Hex package</p>

      <form phx-change="search" phx-submit="go" class="w-full max-w-sm flex flex-col gap-3">
        <input
          autocomplete="off"
          autofocus
          class="w-full px-4 py-2 border border-grey-200 rounded-lg text-grey-700 placeholder-grey-300 focus:border-primary-400 bg-white text-sm"
          type="text"
          name="q"
          value={@query}
          placeholder="Search package..."
        />
        <%= if @suggestions != [] do %>
          <div class="flex flex-wrap gap-2 items-center text-sm text-grey-400">
            <span>Did you mean:</span>
            <%= for suggestion <- @suggestions do %>
              <button
                type="button"
                class="px-2 py-0.5 bg-primary-100 text-primary-700 rounded-md text-xs font-medium hover:bg-primary-200 transition-colors cursor-pointer"
                phx-click={"search_#{suggestion}"}
              ><%= suggestion %></button>
            <% end %>
          </div>
        <% end %>
      </form>

      <%= if length(@releases) == 1 do %>
        <p class="mt-6 text-sm text-grey-400">This package only has one version — nothing to diff.</p>
      <% else %>
        <%= if @result do %>
          <form phx-change="select_version" class="w-full max-w-sm mt-6">
            <div class="flex flex-col gap-4">
              <div class="grid grid-cols-2 gap-3">
                <div class="flex flex-col gap-1">
                  <label for="from-select" class="text-xs font-medium text-grey-500 uppercase tracking-wider">From</label>
                  <select
                    name="from"
                    id="from-select"
                    class="w-full px-3 py-2 border border-grey-200 rounded-lg text-grey-700 text-sm bg-white focus:border-primary-400"
                  >
                    <%= for release_from <- @from_releases do %>
                      <option selected={selected(@from, release_from)} value={release_from}><%= release_from %></option>
                    <% end %>
                  </select>
                </div>
                <div class="flex flex-col gap-1">
                  <label for="to-select" class="text-xs font-medium text-grey-500 uppercase tracking-wider">To</label>
                  <select
                    name="to"
                    id="to-select"
                    class="w-full px-3 py-2 border border-grey-200 rounded-lg text-grey-700 text-sm bg-white focus:border-primary-400"
                  >
                    <%= for release_to <- @to_releases do %>
                      <option selected={selected(@to, release_to)} value={release_to}><%= release_to %></option>
                    <% end %>
                  </select>
                </div>
              </div>
              <button
                type="button"
                disabled={disabled([@from, @to])}
                phx-click="go"
                class="w-full py-2 px-4 bg-primary-600 hover:bg-primary-700 disabled:opacity-40 disabled:cursor-not-allowed text-white text-sm font-semibold rounded-lg transition-colors"
              >View Diff</button>
            </div>
          </form>
        <% end %>
      <% end %>

      <%= if @not_found do %>
        <p class="mt-6 text-sm text-red-600"><%= @not_found %></p>
      <% end %>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, reset_state(socket)}
  end

  def handle_event("search", %{"q" => ""}, socket), do: {:noreply, reset_state(socket)}

  def handle_event("search", %{"q" => query}, socket) do
    query = String.downcase(query)
    send(self(), {:search, query})
    {:noreply, assign(socket, query: query)}
  end

  def handle_event("search_" <> suggestion, _params, socket) do
    send(self(), {:search, suggestion})
    {:noreply, assign(socket, query: suggestion)}
  end

  def handle_event(
        "select_version",
        %{"_target" => ["from"], "from" => from},
        %{assigns: %{releases: releases}} = socket
      ) do
    index_of_selected_from = Enum.find_index(releases, &(&1 == from))
    to_releases = Enum.slice(releases, (index_of_selected_from + 1)..-1)

    {:noreply,
     assign(socket,
       from: from,
       to_releases: to_releases
     )}
  end

  def handle_event(
        "select_version",
        %{"_target" => ["to"], "to" => to},
        socket
      ) do
    {:noreply,
     assign(socket,
       to: to
     )}
  end

  def handle_event("go", _params, %{assigns: %{result: result, to: to, from: from}} = socket)
      when is_binary(result) and is_binary(from) and is_binary(to) do
    {:noreply, redirect(socket, to: build_url(result, from, to))}
  end

  def handle_event("go", _params, socket) do
    {:noreply, socket}
  end

  def handle_info({:search, query}, socket) do
    suggestions = get_suggestions(query, 3)

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
           from: nil,
           releases: []
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

  defp build_url(app, from, to), do: "/diff/#{app}/#{from}..#{to}"

  # Helper functions for template
  defp disabled(things) when is_list(things) do
    Enum.any?(things, &(!&1))
  end

  defp disabled(thing), do: disabled([thing])

  defp selected(x, x), do: true
  defp selected(_, _), do: false

  defp get_suggestions(query, number) do
    package_names = Diff.Package.Store.get_names()
    starts_with = package_starts_with(package_names, query)

    cond do
      length(starts_with) >= number ->
        starts_with

      true ->
        similar_to = package_similar_to(package_names, query)

        Enum.concat(starts_with, similar_to)
        |> Enum.uniq()
    end
    |> Enum.filter(&(&1 != query))
    |> Enum.take(number)
  end

  defp package_starts_with(package_names, query) do
    package_names
    |> Enum.filter(&String.starts_with?(&1, query))
    |> Enum.sort()
  end

  defp package_similar_to(package_names, query) do
    package_names
    |> Stream.map(&{&1, String.jaro_distance(query, &1)})
    |> Stream.filter(fn
      {^query, 1.0} -> false
      {_, value} -> value > 0.8
    end)
    |> Enum.sort(fn {_, v1}, {_, v2} -> v1 > v2 end)
    |> Enum.map(&elem(&1, 0))
  end
end
