defmodule DiffWeb.LayoutView do
  use DiffWeb, :view

  def render("header.html", assigns) do
    package = assigns[:package]
    from = assigns[:from]
    to = assigns[:to]
    assigns = Map.merge(assigns, %{package: package, from: from, to: to})
    render_template("header.html", assigns)
  end
end
