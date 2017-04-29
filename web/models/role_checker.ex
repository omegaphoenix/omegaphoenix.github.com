defmodule TheJuice.RoleChecker do
  alias TheJuice.Repo
  alias TheJuice.Role

  def is_admin?(user) do
    (role = Repo.get(Role, user.role_id)) && role.admin
  end
end
