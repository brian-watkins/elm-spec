module Specs.BrowserEventSpec exposing (..)

import Spec exposing (..)
import Spec.Setup as Setup
import Spec.Markup as Markup
import Spec.Markup.Selector exposing (..)
import Spec.Markup.Event as Event
import Spec.Observer as Observer
import Spec.Step as Step
import Spec.Time
import Html exposing (Html)
import Html.Attributes as Attr
import Browser.Events exposing (Visibility(..))
import Runner
import Json.Decode as Json exposing (Decoder)
import Json.Encode as Encode
import Specs.Helpers exposing (equals)
import Time exposing (Posix)


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
          |> expect (Markup.text <| equals "You wrote: ABACAB")
      )
    )
  ]


keyPressEvent : String -> Step.Context model -> Step.Command msg
keyPressEvent char =
  Encode.object
    [ ( "key", Encode.string char )
    ]
    |> Event.trigger "keypress"


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


mouseDownSpec : Spec Model Msg
mouseDownSpec =
  Spec.describe "browser mouseDown event"
  [ scenario "mouseDown event is triggered" (
      given (
        testSubject
      )
      |> when "a browser mouseDown event occurs"
        [ Markup.target << document
        , Event.mouseDown
        ]
      |> it "fires a mouse down event" (
        Observer.observeModel .mouseDown
          |> expect (equals 1)
      )
    )
  ]


mouseUpSpec : Spec Model Msg
mouseUpSpec =
  Spec.describe "browser mouseUp event"
  [ scenario "mouseUp event is triggered" (
      given (
        testSubject
      )
      |> when "a browser mouseUp event occurs"
        [ Markup.target << document
        , Event.mouseUp
        ]
      |> it "fires a mouse down event" (
        Observer.observeModel .mouseUp
          |> expect (equals 1)
      )
    )
  ]


mouseMoveSpec : Spec Model Msg
mouseMoveSpec =
  Spec.describe "browser mouseMove event"
  [ scenario "mouseMove event is triggered" (
      given (
        testSubject
      )
      |> when "a browser mouseMove event occurs"
        [ Markup.target << document
        , mouseMove (17, 26)
        , mouseMove (20, 31)
        , mouseMove (24, 33)
        ]
      |> it "fires a mouse down event" (
        Observer.observeModel .mouseMove
          |> expect (equals [ (17, 26), (20, 31), (24, 33) ])
      )
    )
  ]


mouseMove : (Int, Int) -> Step.Context model -> Step.Command msg
mouseMove (x, y) =
  Event.trigger "mousemove" <| Encode.object [ ("clientX", Encode.int x), ("clientY", Encode.int y) ]


windowResizeSpec : Spec Model Msg
windowResizeSpec =
  Spec.describe "window resize"
  [ scenario "simulate window resize event" (
      given (
        testSubject
      )
      |> when "a window resize occurs"
        [ Event.resizeWindow (100, 300)
        ]
      |> it "triggers the resize event" (
        Observer.observeModel .resize
          |> expect (equals [(100, 300)])
      )
    )
  ]


windowVisibilitySpec : Spec Model Msg
windowVisibilitySpec =
  Spec.describe "window visibility"
  [ scenario "simulate window visibility change" (
      given (
        testSubject
      )
      |> when "a window visibility change occurs"
        [ Event.hideWindow
        , Event.showWindow
        , Event.hideWindow
        ]
      |> it "triggers the visibility change event" (
        Observer.observeModel .visibility
          |> expect (equals [ Hidden, Visible, Hidden ])
      )
    )
  ]


animationFrameSpec : Spec Model Msg
animationFrameSpec =
  Spec.describe "animationFrame events"
  [ scenario "simulate animation frame event" (
      given (
        testSubject
      )
      |> when "the animation frame updates"
        [ Spec.Time.nextAnimationFrame
        , Spec.Time.nextAnimationFrame
        , Spec.Time.nextAnimationFrame
        ]
      |> it "triggers the onAnimationFrame event" (
        Observer.observeModel .animationFrames
          |> expect (equals 3)
      )
    )
  , scenario "animation frames during ticks" (
      given (
        testSubject
      )
      |> when "time passes"
        [ Spec.Time.tick 1000
        ]
      |> it "triggers the onAnimationFrame event only once" (
        Observer.observeModel .animationFrames
          |> expect (equals 1)
      )
    )
  ]


nonBrowserEventsSpec : Spec Model Msg
nonBrowserEventsSpec =
  Spec.describe "events that don't work as a browser level event"
  [ scenario "mouseMoveIn" (
      given (
        testSubject
      )
      |> when "a mouseMoveIn event is triggered on the document"
        [ Markup.target << document
        , Event.mouseMoveIn
        ]
      |> it "fails" (
        Observer.observeModel .mouseDown
          |> expect (equals 0)
      )
    )
  , scenario "mouseMoveOut" (
      given (
        testSubject
      )
      |> when "a mouseMoveOut event is triggered on the document"
        [ Markup.target << document
        , Event.mouseMoveOut
        ]
      |> it "fails" (
        Observer.observeModel .mouseDown
          |> expect (equals 0)
      )
    )
  ]


noHandlerSpec : Spec Model Msg
noHandlerSpec =
  Spec.describe "events triggered with no handler"
  [ scenario "trigger unhandled event" (
      given (
        testSubject
          |> Setup.withSubscriptions (\_ -> Sub.none)
      )
      |> when "a click event is triggered with no handler"
        [ Markup.target << document
        , Event.click
        ]
      |> when "a mouse up event is triggered with no handler"
        [ Markup.target << document
        , Event.mouseUp
        ]
      |> it "does nothing" (
        Markup.observeElement
          |> Markup.query << by [ id "message" ]
          |> expect (Markup.text <| equals "You wrote: ")
      )
    )
  ]


testSubject =
  Setup.initWithModel { message = "", click = 0, mouseUp = 0, mouseDown = 0, mouseMove = [], resize = [], visibility = [], animationFrames = 0 }
    |> Setup.withView testView
    |> Setup.withUpdate testUpdate
    |> Setup.withSubscriptions testSubscriptions


type Msg
  = GotKey String
  | Click
  | MouseUp
  | MouseDown
  | MouseMove (Int, Int)
  | Resize Int Int
  | VisibilityChange Visibility
  | AnimationFrame Posix


type alias Model =
  { message: String
  , click: Int
  , mouseUp: Int
  , mouseDown: Int
  , mouseMove: List (Int, Int)
  , resize: List (Int, Int)
  , visibility: List Visibility
  , animationFrames: Int
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
    MouseMove point ->
      ( { model | mouseMove = model.mouseMove ++ [ point ] }, Cmd.none )
    Resize height width ->
      ( { model | resize = model.resize ++ [ (height, width) ] }, Cmd.none )
    VisibilityChange visibility ->
      ( { model | visibility = model.visibility ++ [ visibility ] }, Cmd.none )
    AnimationFrame posix ->
      ( { model | animationFrames = model.animationFrames + 1 }, Cmd.none )


testSubscriptions : Model -> Sub Msg
testSubscriptions model =
  Sub.batch
  [ Browser.Events.onKeyPress <| keyDecoder GotKey
  , Browser.Events.onClick <| Json.succeed Click
  , Browser.Events.onMouseDown <| Json.succeed MouseDown
  , Browser.Events.onMouseUp <| Json.succeed MouseUp
  , Browser.Events.onMouseMove <| mouseMoveDecoder MouseMove
  , Browser.Events.onResize Resize
  , Browser.Events.onVisibilityChange VisibilityChange
  , Browser.Events.onAnimationFrame AnimationFrame
  ]


mouseMoveDecoder : ((Int, Int) -> Msg) -> Decoder Msg
mouseMoveDecoder tagger =
  Json.map tagger <| Json.map2 Tuple.pair (Json.field "clientX" Json.int) (Json.field "clientY" Json.int)


keyDecoder : (String -> Msg) -> Decoder Msg
keyDecoder tagger =
  Json.map tagger (Json.field "key" Json.string)


selectSpec : String -> Maybe (Spec Model Msg)
selectSpec name =
  case name of
    "keyboard" -> Just keyboardEventsSpec
    "click" -> Just clickEventSpec
    "mouseDown" -> Just mouseDownSpec
    "mouseUp" -> Just mouseUpSpec
    "mouseMove" -> Just mouseMoveSpec
    "windowResize" -> Just windowResizeSpec
    "nonBrowserEvents" -> Just nonBrowserEventsSpec
    "windowVisibility" -> Just windowVisibilitySpec
    "animationFrame" -> Just animationFrameSpec
    "noHandler" -> Just noHandlerSpec
    _ -> Nothing


main =
  Runner.browserProgram selectSpec