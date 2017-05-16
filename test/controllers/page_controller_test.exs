defmodule TheJuice.PageControllerTest do
  use TheJuice.ConnCase

  test "GET /", %{conn: conn} do
    conn = get conn, "/"
    assert html_response(conn, 200) =~ "Welcome to Justin&#39;s website!"
  end
end
