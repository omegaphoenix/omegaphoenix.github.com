module Components.ArticleList exposing (..)

import Html exposing (Html, text, ul, li, div, h2, button)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
import List
import Article

type alias Model =
  { articles: List Article.Model }

articles : Model
articles =
  { articles =
    [ { title = "Project Plan", url = "https://omegaphoenix.github.io/", postedBy = "justin", postedOn = "07/02/17" }
    , { title = "Meeting Notes", url = "https://omegaphoenix.github.io/", postedBy = "justin", postedOn = "07/02/17" }
    , { title = "Post 1", url = "https://jkleong.com/users/justin/posts/1/", postedBy = "justin", postedOn = "07/02/17" } ] }

type Msg
  = NoOp
  | Fetch

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    NoOp ->
      (model, Cmd.none)
    Fetch ->
      (articles, Cmd.none)

initialModel : Model
initialModel =
  { articles = [] }

renderArticle : Article.Model -> Html a
renderArticle article =
  li [ ] [ Article.view article ]

renderArticles : Model -> List (Html a)
renderArticles model =
  List.map renderArticle model.articles

view : Model -> Html Msg
view model =
  div [ class "article-list" ]
    [ h2 [] [ text "Article List" ]
    , button [ onClick Fetch, class "btn btn-primary" ] [ text "Fetch Articles" ]
    , ul [] (renderArticles model) ]
