defmodule TaksoWeb.PageControllerTest do
  use TaksoWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Welcome to Takso!"
  end
end
