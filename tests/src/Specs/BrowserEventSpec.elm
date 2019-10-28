module Specs.BrowserEventSpec exposing (..)

import Spec exposing (Spec)
import Spec.Subject as Subject
import Spec.Scenario exposing (..)
import Spec.Markup as Markup
import Spec.Markup.Selector exposing (..)
import Spec.Markup.Event as Event
import Spec.Observer as Observer
import Spec.Step as Step
import Html exposing (Html)
import Html.Attributes as Attr
import Browser.Events
import Runner
import Json.Decode as Json exposing (Decoder)
import Json.Encode as Encode
import Specs.Helpers exposing (equals)


keyboardEventsSpec : Spec Model Msg
keyboardEventsSpec =
  Spec.describe "Browser keyboard events"
  [ scenario "key press event is triggered" (
      given (
        testSubject
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


clickEventSpec : Spec Model Msg
clickEventSpec =
  Spec.describe "browser click event"
  [ scenario "click event is triggered" (
      given (
        testSubject
      )
      |> when "a browser click event occurs"
        [ Markup.target << document
        , Event.click
        , Event.click
        , Event.click
        ]
      |> observeThat
        [ it "handles the event" (
            Observer.observeModel .click
              |> expect (equals 3)
          )
        , it "fires a mouse down event" (
            Observer.observeModel .mouseDown
              |> expect (equals 3)
          )
        , it "fires a mouse up event" (
            Observer.observeModel .mouseUp
              |> expect (equals 3)
          )
        ]
    )
  ]


testSubject =
  Subject.initWithModel { message = "", click = 0, mouseUp = 0, mouseDown = 0 }
    |> Subject.withView testView
    |> Subject.withUpdate testUpdate
    |> Subject.withSubscriptions testSubscriptions


keyPressEvent : String -> Step.Context model -> Step.Command msg
keyPressEvent char =
  Encode.object
    [ ( "key", Encode.string char )
    ]
    |> Event.trigger "keypress"

type Msg
  = GotKey String
  | Click
  | MouseUp
  | MouseDown

type alias Model =
  { message: String
  , click: Int
  , mouseUp: Int
  , mouseDown: Int
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
    Click ->
      ( { model | click = model.click + 1 }, Cmd.none )
    MouseUp ->
      ( { model | mouseUp = model.mouseUp + 1 }, Cmd.none )
    MouseDown ->
      ( { model | mouseDown = model.mouseDown + 1 }, Cmd.none )

testSubscriptions : Model -> Sub Msg
testSubscriptions model =
  Sub.batch
  [ Browser.Events.onKeyPress <| keyDecoder GotKey
  , Browser.Events.onClick <| Json.succeed Click
  , Browser.Events.onMouseDown <| Json.succeed MouseDown
  , Browser.Events.onMouseUp <| Json.succeed MouseUp
  ]


keyDecoder : (String -> Msg) -> Decoder Msg
keyDecoder tagger =
  Json.map tagger (Json.field "key" Json.string)


selectSpec : String -> Maybe (Spec Model Msg)
selectSpec name =
  case name of
    "keyboard" -> Just keyboardEventsSpec
    "click" -> Just clickEventSpec
    _ -> Nothing


main =
  Runner.browserProgram selectSpec