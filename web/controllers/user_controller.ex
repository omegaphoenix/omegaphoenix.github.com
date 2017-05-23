defmodule TheJuice.UserController do
  use TheJuice.Web, :controller

  alias TheJuice.User
  alias TheJuice.Role

  plug :scrub_params, "user" when action in [:create, :update]
  plug :authorize_admin when action in [:new, :create]
  plug :authorize_user when action in [:edit, :update, :delete]

  def index(conn, _params) do
    users = Repo.all(User)
    render(conn, "index.html", users: users)
  end

  def show(conn, %{"username" => username}) do
    user = Repo.get_by!(User, username: username)
    render(conn, "show.html", user: user)
  end

  def new(conn, _params) do
    roles = Repo.all(Role)
    changeset = User.changeset(%User{})
    render(conn, "new.html", changeset: changeset, roles: roles)
  end

  def edit(conn, %{"username" => username}) do
    roles = Repo.all(Role)
    user = Repo.get_by!(User, username: username)
    changeset = User.changeset(user)
    render(conn, "edit.html", user: user, changeset: changeset, roles: roles)
  end

  def create(conn, %{"user" => user_params}) do
    roles = Repo.all(Role)
    changeset = User.changeset(%User{}, user_params)

    case Repo.insert(changeset) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "User created successfully.")
        |> redirect(to: user_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset, roles: roles)
    end
  end

  def update(conn, %{"username" => username, "user" => user_params}) do
    roles = Repo.all(Role)
    user = Repo.get_by!(User, username: username)
    changeset = User.changeset(user, user_params)

    case Repo.update(changeset) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "User updated successfully.")
        |> redirect(to: user_path(conn, :show, user))
      {:error, changeset} ->
        render(conn, "edit.html", user: user, changeset: changeset, roles: roles)
    end
  end

  def delete(conn, %{"username" => username}) do
    user = Repo.get_by!(User, username: username)

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(user)

    conn
    |> put_flash(:info, "User deleted successfully.")
    |> redirect(to: user_path(conn, :index))
  end

  defp authorize_user(conn, _) do
    user = get_session(conn, :current_user)
    if user && (Integer.to_string(user.id) == conn.params["id"] || TheJuice.RoleChecker.is_admin?(user)) do
      conn
    else
      conn
      |> put_flash(:error, "You are not authorized to modify that user!")
      |> redirect(to: page_path(conn, :index))
      |> halt()
    end
  end

  defp authorize_admin(conn, _) do
    user = get_session(conn, :current_user)
    if user && TheJuice.RoleChecker.is_admin?(user) do
      conn
    else
      conn
      |> put_flash(:error, "You are not authorized to create new users!")
      |> redirect(to: page_path(conn, :index))
      |> halt()
    end
  end
end
