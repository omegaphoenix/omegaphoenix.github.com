defmodule TheJuice.PageController do
  use TheJuice.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
