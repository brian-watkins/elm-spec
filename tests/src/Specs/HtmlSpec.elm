module Specs.HtmlSpec exposing (..)

import Spec exposing (Spec)
import Spec.Subject as Subject
import Spec.Html as Markup
import Spec.Html.Selector exposing (..)
import Spec.Html.Event as Event
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
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


clickSpec : Spec Model Msg
clickSpec =
  Spec.given "an html program with a click event" (
    Subject.initWithModel { name = "Cool Dude", count = 0 }
      |> Subject.withUpdate testUpdate
      |> Subject.withView testView
  )
  |> Spec.when "the button is clicked three times"
    [ Markup.target << by [ id "my-button" ]
    , Event.click
    , Event.click
    , Event.click
    ]
  |> Spec.when "the other button is clicked once"
    [ Markup.target << by [ id "another-button" ]
    , Event.click
    ]
  |> Spec.it "renders the count" (
    Markup.select << by [ id "my-count" ]
      |> Markup.expect (Markup.hasText "The count is 30!")
  )


testView : Model -> Html Msg
testView model =
  Html.div []
  [ Html.div [ Attr.id "my-name" ] [ Html.text <| "Hello, " ++ model.name ++ "!" ]
  , Html.div [ Attr.id "my-count" ] [ Html.text <| "The count is " ++ String.fromInt model.count ++ "!" ]
  , Html.button [ Attr.id "my-button", Events.onClick HandleClick ] [ Html.text "Click me!" ]
  , Html.button [ Attr.id "another-button", Events.onClick HandleMegaClick ] [ Html.text "Click me!" ]
  ]


type Msg
  = HandleClick
  | HandleMegaClick


type alias Model =
  { name: String
  , count: Int
  }


testUpdate : Msg -> Model -> (Model, Cmd Msg)
testUpdate msg model =
  case msg of
    HandleClick ->
      ( { model | count = model.count + 1 }, Cmd.none )
    HandleMegaClick ->
      ( { model | count = model.count * 10 }, Cmd.none )


selectSpec : String -> Spec Model Msg
selectSpec name =
  case name of
    "single" -> htmlSpecSingle
    "multiple" -> htmlSpecMultiple
    "hasTextFails" -> hasTextFails
    "click" -> clickSpec
    _ -> htmlSpecSingle


main =
  Runner.browserProgram selectSpec