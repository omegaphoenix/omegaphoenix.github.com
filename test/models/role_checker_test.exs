defmodule TheJuice.RoleCheckerTest do
  use TheJuice.ModelCase
  alias TheJuice.TestHelper
  alias TheJuice.RoleChecker

  test "is_admin? is true when user has an admin role" do
    {:ok, role} = TestHelper.create_role(%{name: "Admin", admin: true})
    {:ok, user} = TestHelper.create_user(role, %{email: "test@test.com", username: "user", password: "test", password_confirmation: "test"})
    assert RoleChecker.is_admin?(user)
  end

  test "is_admin? is false when user does not have an admin role" do
    {:ok, role} = TestHelper.create_role(%{name: "User", admin: false})
    {:ok, user} = TestHelper.create_user(role, %{email: "test@test.com", username: "user", password: "test", password_confirmation: "test"})
    refute RoleChecker.is_admin?(user)
  end
end
