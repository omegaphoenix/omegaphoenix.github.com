defmodule TheJuice.Factory do
  use ExMachina.Ecto, repo: TheJuice.Repo

  alias TheJuice.Comment
  alias TheJuice.Post
  alias TheJuice.Role
  alias TheJuice.User

  def role_factory do
    %Role{
      name: sequence(:name, &"Test Role #{&1}"),
      admin: false
    }
  end

  def user_factory do
    %User{
      username: sequence(:username, &"User #{&1}"),
      email: "test@test.com",
      password: "test1234",
      password_confirmation: "test1234",
      password_digest: Comeonin.Bcrypt.hashpwsalt("test1234"),
      role: build(:role)
    }
  end

  def post_factory do
    %Post{
      title: "Some Post",
      body: "And the body of some post",
      user: build(:user)
    }
  end

  def comment_factory do
		%Comment{
			author: "Test User",
			body: "This is a sample comment",
			approved: false,
			post: build(:post)
		}
	end
end
