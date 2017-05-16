defmodule TheJuice.PageController do
  use TheJuice.Web, :controller

  alias TheJuice.User

  def index(conn, _params) do
    users = Repo.all(User)
    render(conn, "index.html", users: users)
  end
end
