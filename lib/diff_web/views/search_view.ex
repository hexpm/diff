defmodule DiffWeb.SearchView do
  use DiffWeb, :view

  def disabled(things) when is_list(things) do
    if Enum.any?(things, &(!&1)) do
      "disabled"
    else
      ""
    end
  end

  def disabled(thing), do: disabled([thing])

  def selected(x, x), do: "selected=selected"
  def selected(_, _), do: ""
end
