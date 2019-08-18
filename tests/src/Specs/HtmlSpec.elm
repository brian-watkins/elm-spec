module Specs.HtmlSpec exposing (..)

import Spec exposing (Spec)
import Spec.Subject as Subject
import Spec.Html as Markup
import Spec.Html.Selector exposing (..)
import Html exposing (Html)
import Html.Attributes as Attr
import Runner


htmlSpecSingle : Spec Model Msg
htmlSpecSingle =
  Spec.given "an html program with a single observation" (
    Subject.initWithModel { name = "Cool Dude", count = 78 }
      |> Subject.withView testView
  )
  |> Spec.it "renders the name based on the model" (
    Markup.select << by [ id "my-name" ]
      |> Markup.expect (Markup.hasText "Hello, Cool Dude!")
  )


htmlSpecMultiple : Spec Model Msg
htmlSpecMultiple =
  Spec.given "an html program with multiple observations" (
    Subject.initWithModel { name = "Cool Dude", count = 78 }
      |> Subject.withView testView
  )
  |> Spec.it "renders the name based on the model" (
    Markup.select << by [ id "my-name" ]
      |> Markup.expect (Markup.hasText "Hello, Cool Dude!")
  )
  |> Spec.it "renders the count based on the model" (
    Markup.select << by [ id "my-count" ]
      |> Markup.expect (Markup.hasText "The count is 78!")
  )


hasTextFails : Spec Model Msg
hasTextFails =
  Spec.given "an html program with a failing observation" (
    Subject.initWithModel { name = "Cool Dude", count = 78 }
      |> Subject.withView testView
  )
  |> Spec.it "renders the name based on the model" (
    Markup.select << by [ id "my-name" ]
      |> Markup.expect (Markup.hasText "Something not present")
  )


testView : Model -> Html Msg
testView model =
  Html.div []
  [ Html.div [ Attr.id "my-name" ] [ Html.text <| "Hello, " ++ model.name ++ "!" ]
  , Html.div [ Attr.id "my-count" ] [ Html.text <| "The count is " ++ String.fromInt model.count ++ "!" ]
  ]


type Msg =
  Msg


type alias Model =
  { name: String
  , count: Int
  }


selectSpec : String -> Spec Model Msg
selectSpec name =
  case name of
    "single" -> htmlSpecSingle
    "multiple" -> htmlSpecMultiple
    "hasTextFails" -> hasTextFails
    _ -> htmlSpecSingle


main =
  Runner.browserProgram selectSpec