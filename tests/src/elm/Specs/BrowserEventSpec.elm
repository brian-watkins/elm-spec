module Specs.BrowserEventSpec exposing (..)

import Spec exposing (..)
import Spec.Setup as Setup
import Spec.Markup as Markup
import Spec.Markup.Selector exposing (..)
import Spec.Markup.Event as Event
import Spec.Navigator as Navigator
import Spec.Observer as Observer
import Spec.Step as Step
import Spec.Claim exposing (..)
import Spec.Command
import Spec.Time
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Browser.Events exposing (Visibility(..))
import Browser.Dom as Dom
import Runner
import Json.Decode as Json exposing (Decoder)
import Json.Encode as Encode
import Specs.Helpers exposing (equals, itShouldHaveFailedAlready)
import Time exposing (Posix)
import Task


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
          |> expect (isSomethingWhere <| Markup.text <| equals "You wrote: ABACAB")
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
  [ scenario "default window size" (
      given (
        testSubject
      )
      |> when "the viewport is requested"
        [ Spec.Command.send (Dom.getViewport |> Task.perform GotViewport)
        ]
      |> it "shows the default size" (
        Observer.observeModel .viewport
          |> expect (isSomethingWhere <| specifyThat .viewport <| satisfying
            [ specifyThat .width <| equals 1280
            , specifyThat .height <| equals 800
            ]
          )
      )
    )
  , scenario "trigger window resize event" (
      given (
        testSubject
      )
      |> when "a window resize occurs"
        [ Navigator.resize (100, 300)
        ]
      |> observeThat
        [ it "triggers the resize event" (
            Observer.observeModel .resize
              |> expect (equals [(100, 300)])
          )
        , it "updates the viewport" (
            Observer.observeModel .viewport
              |> expect (isSomethingWhere <| specifyThat .viewport <| satisfying
                [ specifyThat .width <| equals 100
                , specifyThat .height <| equals 300
                ]
              )
          )
        ]
    )
  , scenario "another scenario simulates a resize" (
      given (
        testSubject
      )
      |> when "a window resize occurs"
        [ Navigator.resize (200, 450)
        ]
      |> it "triggers the resize event" (
        Observer.observeModel .resize
          |> expect (equals [(200, 450)])
      )
    )
  , scenario "the app stops subscribing during the spec" (
      given (
        testSubject
      )
      |> when "a window resize occurs"
        [ Navigator.resize (200, 450)
        ]
      |> when "the app unsubscribes from resize events"
        [ Markup.target << by [ id "toggle-subs" ]
        , Event.click
        ]
      |> when "another window resize occurs"
        [ Navigator.resize (300, 550)
        ]
      |> it "no longer updates the size" (
        Observer.observeModel .resize
          |> expect (equals [(200, 450)])
      )
    )
  , scenario "resets to default after previous scenario changes size" (
      given (
        testSubject
      )
      |> when "the viewport is requested"
        [ Spec.Command.send (Dom.getViewport |> Task.perform GotViewport)
        ]
      |> it "shows the default size" (
        Observer.observeModel .viewport
          |> expect (isSomethingWhere <| specifyThat .viewport <| satisfying
            [ specifyThat .width <| equals 1280
            , specifyThat .height <| equals 800
            ]
          )
      )
    )
  ]


getViewportOnInitSpec : Spec Model Msg
getViewportOnInitSpec =
  Spec.describe "get viewport"
  [ scenario "on init" (
      given (
        Setup.init (testModel, Dom.getViewport |> Task.perform GotViewport)
          |> Setup.withView testView
          |> Setup.withUpdate testUpdate
      )
      |> it "shows the default size" (
        Observer.observeModel .viewport
          |> expect (isSomethingWhere <| specifyThat .viewport <| satisfying
            [ specifyThat .width <| equals 1280
            , specifyThat .height <| equals 800
            ]
          )
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
        [ Navigator.hide
        , Navigator.show
        , Navigator.hide
        ]
      |> it "triggers the visibility change event" (
        Observer.observeModel .visibility
          |> expect (equals [ Hidden, Visible, Hidden ])
      )
    )
  , scenario "another scenario simulates the visibility change" (
      given (
        testSubject
      )
      |> when "a window visibility change occurs"
        [ Navigator.hide
        , Navigator.show
        , Navigator.hide
        , Navigator.show
        ]
      |> it "triggers the visibility change event" (
        Observer.observeModel .visibility
          |> expect (equals [ Hidden, Visible, Hidden, Visible ])
      )
    )
  , scenario "the app stops subscribing during the scenario" (
      given (
        testSubject
      )
      |> when "a window visibility change occurs"
        [ Navigator.hide
        , Navigator.show
        ]
      |> when "the app unsubscribes from visibility change events"
        [ Markup.target << by [ id "toggle-subs" ]
        , Event.click
        ]
      |> when "another window visibility change occurs"
        [ Navigator.hide
        , Navigator.show
        , Navigator.hide
        , Navigator.show
        ]
      |> it "only records the changes when the app was subscribed" (
        Observer.observeModel .visibility
          |> expect (equals [ Hidden, Visible ])
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
      |> it "triggers the onAnimationFrame event three times plus once for the initial command" (
        Observer.observeModel .animationFrames
          |> expect (equals 4)
      )
    )
  , scenario "animation frames during ticks" (
      given (
        testSubject
      )
      |> when "time passes"
        [ Spec.Time.tick 1000
        ]
      |> it "triggers the onAnimationFrame event once for the initial command, once for the 1000ms, and once for the end of the step" (
        Observer.observeModel .animationFrames
          |> expect (equals 3)
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
      |> itShouldHaveFailedAlready
    )
  , scenario "mouseMoveOut" (
      given (
        testSubject
      )
      |> when "a mouseMoveOut event is triggered on the document"
        [ Markup.target << document
        , Event.mouseMoveOut
        ]
      |> itShouldHaveFailedAlready
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
          |> expect (isSomethingWhere <| Markup.text <| equals "You wrote: ")
      )
    )
  ]


testSubject =
  Setup.initWithModel testModel
    |> Setup.withView testView
    |> Setup.withUpdate testUpdate
    |> Setup.withSubscriptions testSubscriptions
    |> Spec.Time.allowExtraAnimationFrames


type Msg
  = GotKey String
  | Click
  | MouseUp
  | MouseDown
  | MouseMove (Int, Int)
  | Resize Int Int
  | VisibilityChange Visibility
  | AnimationFrame Posix
  | ShouldSubscribe Bool
  | GotViewport Dom.Viewport


type alias Model =
  { message: String
  , click: Int
  , mouseUp: Int
  , mouseDown: Int
  , mouseMove: List (Int, Int)
  , resize: List (Int, Int)
  , visibility: List Visibility
  , subscribe: Bool
  , animationFrames: Int
  , viewport: Maybe Dom.Viewport
  }


testModel : Model
testModel =
  { message = ""
  , click = 0
  , mouseUp = 0
  , mouseDown = 0
  , mouseMove = []
  , resize = []
  , visibility = []
  , subscribe = True
  , animationFrames = 0
  , viewport = Nothing
  }


testView : Model -> Html Msg
testView model =
  Html.div []
  [ Html.div [ Attr.id "message" ] [ Html.text <| "You wrote: " ++ model.message ]
  , Html.input
    [ Attr.id "toggle-subs"
    , Attr.type_ "checkbox"
    , Attr.checked model.subscribe
    , Events.onCheck ShouldSubscribe
    ]
    [ Html.text "Subscribe to Events" ]
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
      ( { model | resize = model.resize ++ [ (height, width) ] }
      , Dom.getViewport |> Task.perform GotViewport
      )
    VisibilityChange visibility ->
      ( { model | visibility = model.visibility ++ [ visibility ] }, Cmd.none )
    AnimationFrame posix ->
      ( { model | animationFrames = model.animationFrames + 1 }, Cmd.none )
    ShouldSubscribe shouldSubscribe ->
      ( { model | subscribe = shouldSubscribe }, Cmd.none )
    GotViewport viewport ->
      ( { model | viewport = Just viewport }, Cmd.none )


testSubscriptions : Model -> Sub Msg
testSubscriptions model =
  Sub.batch
    [ Browser.Events.onKeyPress <| keyDecoder GotKey
    , Browser.Events.onClick <| Json.succeed Click
    , Browser.Events.onMouseDown <| Json.succeed MouseDown
    , Browser.Events.onMouseUp <| Json.succeed MouseUp
    , Browser.Events.onMouseMove <| mouseMoveDecoder MouseMove
    , if model.subscribe then
        Browser.Events.onResize Resize
      else
        Sub.none
    , if model.subscribe then 
        Browser.Events.onVisibilityChange VisibilityChange 
      else
        Sub.none
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
    "getViewportOnInit" -> Just getViewportOnInitSpec
    _ -> Nothing


main =
  Runner.browserProgram selectSpec