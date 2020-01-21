defmodule DiffWeb.SearchLiveView do
  use Phoenix.LiveView

  def render(assigns) do
    DiffWeb.SearchView.render("search.html", assigns)
  end

  @valid_query ~r{^[a-zA-Z0-9_]+$}

  def mount(_session, socket) do
    {:ok, reset_state(socket)}
  end

  def handle_event("search", %{"q" => ""}, socket), do: {:noreply, reset_state(socket)}

  def handle_event("search", %{"q" => query}, socket)
      when byte_size(query) > 30 do
    {:noreply, socket}
  end

  def handle_event("search", %{"q" => query}, socket) do
    if String.match?(query, @valid_query) do
      query = String.downcase(query)
      send(self(), {:search, query})
      {:noreply, assign(socket, query: query)}
    else
      {:noreply, socket}
    end
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

    {:noreply, assign(socket, from: from, to_releases: to_releases)}
  end

  def handle_event(
        "select_version",
        %{"_target" => ["to"], "to" => to},
        socket
      ) do
    {:noreply, assign(socket, to: to)}
  end

  def handle_event("go", _params, %{assigns: %{result: result, to: to, from: from}} = socket)
      when is_binary(result) and is_binary(from) and is_binary(to) do
    {:stop, redirect(socket, to: build_url(result, from, to))}
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

  defp build_url(app, from, to), do: "/diff/#{app}/#{from}..#{to}"

  defp get_suggestions(query, number) do
    package_names = Diff.Package.Store.get_names()
    starts_with = package_starts_with(package_names, query)

    cond do
      length(starts_with) >= number ->
        starts_with

      true ->
        similar_to = package_similar_to(package_names, query)
        Enum.concat(starts_with, similar_to)
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
