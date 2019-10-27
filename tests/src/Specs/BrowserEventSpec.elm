module Specs.BrowserEventSpec exposing (..)

import Spec exposing (Spec)
import Spec.Subject as Subject
import Spec.Scenario exposing (..)
import Spec.Markup as Markup
import Spec.Markup.Selector exposing (..)
import Spec.Markup.Event as Event
import Spec.Step as Step
import Html exposing (Html)
import Html.Attributes as Attr
import Browser.Events
import Runner
import Json.Decode as Json exposing (Decoder)
import Json.Encode as Encode


keyboardEventsSpec : Spec Model Msg
keyboardEventsSpec =
  Spec.describe "Browser keyboard events"
  [ scenario "key press event is triggered" (
      given (
        Subject.initWithModel { message = "" }
          |> Subject.withView testView
          |> Subject.withUpdate testUpdate
          |> Subject.withSubscriptions testSubscriptions
      )
      |> when "key presses are triggered"
        [ Markup.target << document
        , keyPressEvent "A"
        , keyPressEvent "B"
        , keyPressEvent "A"
        , keyPressEvent "C"
        , keyPressEvent "A"
        , keyPressEvent "B"
        ]
      |> it "handles the event" (
        Markup.observeElement
          |> Markup.query << by [ id "message" ]
          |> expect (Markup.hasText "You wrote: ABACAB")
      )
    )
  ]

keyPressEvent : String -> Step.Context model -> Step.Command msg
keyPressEvent char =
  Encode.object
    [ ( "key", Encode.string char )
    ]
    |> Event.trigger "keypress"

type Msg
  = GotKey String

type alias Model =
  { message: String
  }

testView : Model -> Html Msg
testView model =
  Html.div []
  [ Html.div [ Attr.id "message" ] [ Html.text <| "You wrote: " ++ model.message ]
  ]

testUpdate : Msg -> Model -> ( Model, Cmd Msg )
testUpdate msg model =
  case msg of
    GotKey key ->
      ( { model | message = model.message ++ key }, Cmd.none )

testSubscriptions : Model -> Sub Msg
testSubscriptions model =
  keyDecoder GotKey
    |> Browser.Events.onKeyPress

keyDecoder : (String -> Msg) -> Decoder Msg
keyDecoder tagger =
  Json.map tagger (Json.field "key" Json.string)


selectSpec : String -> Maybe (Spec Model Msg)
selectSpec name =
  case name of
    "keyboard" -> Just keyboardEventsSpec
    _ -> Nothing


main =
  Runner.browserProgram selectSpec