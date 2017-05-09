defmodule TheJuice.PostView do
  use TheJuice.Web, :view

  def markdown(body) do
    body
    |> Earmark.as_html!
    |> raw
  end
end
