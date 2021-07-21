defmodule DiffWeb.ErrorViewTest do
  use DiffWeb.ConnCase, async: true

  # Bring render/3 and render_to_string/3 for testing custom views
  import Phoenix.View

  test "renders 404.html" do
    assert render_to_string(DiffWeb.ErrorView, "404.html", []) =~ "Page not found"
  end

  test "renders 500.html" do
    assert render_to_string(DiffWeb.ErrorView, "500.html", []) =~ "Something went wrong"
  end
end
