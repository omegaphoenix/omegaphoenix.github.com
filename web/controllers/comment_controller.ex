defmodule TheJuice.CommentController do
  use TheJuice.Web, :controller

  alias TheJuice.Comment
  alias TheJuice.Post

  plug :scrub_params, "comment" when action in [:create, :update]

  def create(conn, %{"comment" => comment_params, "post_id" => post_id}) do
    post      = Repo.get!(Post, post_id) |> Repo.preload([:user, :comments])
    changeset = post
      |> build_assoc(:comments)
      |> Comment.changeset(comment_params)
    case Repo.insert(changeset) do
      {:ok, _comment} ->
        conn
        |> put_flash(:info, "Comment created successfully!")
        |> redirect(to: user_post_path(conn, :show, post.user, post))
      {:error, changeset} ->
        render(conn, TheJuice.PostView, "show.html", post: post, user: post.user, comment_changeset: changeset)
    end
  end

  def update(conn, %{"id" => id, "post_id" => post_id, "comment" => comment_params}) do
    post = Repo.get!(Post, post_id) |> Repo.preload(:user)
    comment = Repo.get!(Comment, id)
    changeset = Comment.changeset(comment, comment_params)

    case Repo.update(changeset) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Comment updated successfully.")
        |> redirect(to: user_post_path(conn, :show, post.user, post))
      {:error, _} ->
        conn
        |> put_flash(:info, "Failed to update comment!")
        |> redirect(to: user_post_path(conn, :show, post.user, post))
    end
  end

  def delete(conn, %{"id" => id, "post_id" => post_id}) do
    post = Repo.get!(Post, post_id) |> Repo.preload(:user)
    Repo.get!(Comment, id) |> Repo.delete!
    conn
    |> put_flash(:info, "Deleted comment!")
    |> redirect(to: user_post_path(conn, :show, post.user, post))
  end
end
