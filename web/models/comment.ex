defmodule TheJuice.Comment do
  use TheJuice.Web, :model

  schema "comments" do
    field :author, :string
    field :body, :string
    field :approved, :boolean, default: false
    belongs_to :post, TheJuice.Post

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:author, :body, :approved])
    |> validate_required([:author, :body, :approved])
  end
end
