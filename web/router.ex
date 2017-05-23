defmodule TheJuice.Router do
  use TheJuice.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", TheJuice do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
    resources "/users", UserController, param: "username" do
      resources "/posts", PostController
    end
    resources "/sessions", SessionController, only: [:new, :create, :delete]
    resources "/posts", PostController, only: [] do
      resources "/comments", CommentController, only: [:create, :delete, :update]
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", TheJuice do
  #   pipe_through :api
  # end
end
