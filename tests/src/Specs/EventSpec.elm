module Specs.EventSpec exposing (..)

import Spec exposing (Spec)
import Spec.Subject as Subject
import Spec.Scenario exposing (..)
import Spec.Markup as Markup
import Spec.Markup.Selector exposing (..)
import Spec.Markup.Event as Event
import Spec.Observation as Observation
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Runner


inputSpec : Spec Model Msg
inputSpec =
  Spec.describe "an html program"
  [ scenario "Input event" (
      given (
        Subject.initWithModel { message = "" }
          |> Subject.withUpdate testUpdate
          |> Subject.withView testView
      )
      |> when "some text is input"
        [ target << by [ id "my-field" ]
        , Event.input "Here is some fun text!"
        ]
      |> it "renders the text on the view" (
        Markup.observeElement
          |> Markup.query << by [ id "my-message" ]
          |> expect (Markup.hasText "You wrote: Here is some fun text!")
      )
    )
  ]


type Msg =
  GotText String


type alias Model =
  { message: String
  }


testUpdate : Msg -> Model -> (Model, Cmd Msg)
testUpdate msg model =
  case msg of
    GotText message ->
      ( { model | message = message }, Cmd.none )


testView : Model -> Html Msg
testView model =
  Html.div []
  [ Html.input [ Attr.id "my-field", Events.onInput GotText ] []
  , Html.div [ Attr.id "my-message" ] [ Html.text <| "You wrote: " ++ model.message ]
  ]


selectSpec : String -> Maybe (Spec Model Msg)
selectSpec name =
  Just inputSpec


main =
  Runner.browserProgram selectSpec