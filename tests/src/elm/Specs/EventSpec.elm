module Specs.EventSpec exposing (..)

import Spec exposing (..)
import Spec.Setup as Setup
import Spec.Step as Step
import Spec.Markup as Markup
import Spec.Markup.Selector exposing (..)
import Spec.Markup.Event as Event
import Spec.Observer as Observer
import Specs.Helpers exposing (..)
import Specs.EventHelpers
import Spec.Report as Report
import Spec.Claim as Claim exposing (isSomethingWhere)
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Runner
import Json.Decode as Json
import Json.Encode as Encode


clickSpec : Spec Model Msg
clickSpec =
  Spec.describe "an html program"
  [ scenario "a click event" (
      given (
        testSubject
      )
      |> when "the button is clicked three times"
        [ Markup.target << by [ id "my-button" ]
        , Event.click
        , Event.click
        , Event.click
        ]
      |> when "the other button is clicked once"
        [ Markup.target << by [ id "another-button" ]
        , Event.click
        ]
      |> it "renders the count" (
        Markup.observeElement
          |> Markup.query << by [ id "my-count" ]
          |> expect (isSomethingWhere <| Markup.text <| equals "The count is 30!")
      )
    )
  , scenario "mousedown and mouseup events" (
      given (
        testSubject
      )
      |> when "an element is clicked"
        [ Markup.target << by [ id "my-button" ]
        , Event.click
        , Event.click
        ]
      |> observeThat
        [ it "fires a mouseup event" (
            Observer.observeModel .mouseUp
              |> expect (equals 2)
          )
        , it "fires a mousedown event" (
            Observer.observeModel .mouseDown
              |> expect (equals 2)
          )
        ]
    )
  , scenario "no element targeted for click" (
      given (
        testSubject
      )
      |> when "no element is targeted for a click"
        [ Event.click
        ]
      |> itShouldHaveFailedAlready
    )
  , scenario "view re-renders before click event" (
      given (
        testSubjectWithConditionalElement <|
          { on = [ Html.div [ Attr.id "conditional", Events.onClick ConditionalTrigger ] [] ]
          , off = []
          }
      )
      |> when "click in the conditional area"
        [ Markup.target << by [ id "conditional" ]
        , Event.click
        , Event.click
        , Event.click
        ]
      |> itShouldHaveFailedAlready
    )
  ]


doubleClickSpec : Spec Model Msg
doubleClickSpec =
  Spec.describe "double click"
  [ scenario "a double click event" (
      given (
        testSubject
      )
      |> when "a double click event occurs"
        [ Markup.target << by [ id "tap-twice-area" ]
        , Event.doubleClick
        ]
      |> observeThat
        [ it "responds to the event" (
            Markup.observeElement
              |> Markup.query << by [ id "my-message" ]
              |> expect (isSomethingWhere <| Markup.text <| equals "You wrote: DOUBLE CLICK!")
          )
        , it "records two click events" (
            Observer.observeModel .count
              |> expect (equals 2)
          )
        , it "fires two mouseup events" (
            Observer.observeModel .mouseUp
              |> expect (equals 2)
          )
        , it "fires two mousedown events" (
            Observer.observeModel .mouseDown
              |> expect (equals 2)
          )
        ]
    )
  , eventStepFailsWhenNoElementTargeted Event.doubleClick
  , scenario "view re-renders before double click event" (
      given (
        testSubjectWithConditionalElement <|
          { on = [ Html.div [ Attr.id "conditional", Events.onDoubleClick ConditionalTrigger ] [] ]
          , off = []
          }
      )
      |> when "double click in the conditional area"
        [ Markup.target << by [ id "conditional" ]
        , Event.doubleClick
        , Event.doubleClick
        , Event.doubleClick
        ]
      |> itShouldHaveFailedAlready
    )
  ]


mouseDownSpec : Spec Model Msg
mouseDownSpec =
  Spec.describe "mouse down"
  [ scenario "a mouse down event" (
      given (
        testSubject
      )
      |> when "a mouse down event occurs"
        [ Markup.target << by [ id "tap-area" ]
        , Event.mouseDown
        ]
      |> it "responds to the event" (
        Markup.observeElement
          |> Markup.query << by [ id "my-message" ]
          |> expect (isSomethingWhere <| Markup.text <| equals "You wrote: MOUSE DOWN!")
      )
    )
  , scenario "no element targeted for mouse down" (
      given (
        testSubject
      )
      |> when "a mouse down event occurs but no element is targeted"
        [ Event.mouseDown
        ]
      |> itShouldHaveFailedAlready
    )
  , scenario "view re-renders before mouseDown event" (
      given (
        testSubjectWithConditionalElement <|
          { on = [ Html.div [ Attr.id "conditional", Events.onMouseDown ConditionalTrigger ] [] ]
          , off = []
          }
      )
      |> when "mouse down in the conditional area"
        [ Markup.target << by [ id "conditional" ]
        , Event.mouseDown
        , Event.mouseDown
        , Event.mouseDown
        ]
      |> itShouldHaveFailedAlready
    )
  ]


mouseUpSpec : Spec Model Msg
mouseUpSpec =
  Spec.describe "mouse up"
  [ scenario "a mouse up event" (
      given (
        testSubject
      )
      |> when "a mouse up event occurs"
        [ Markup.target << by [ id "tap-area" ]
        , Event.mouseUp
        ]
      |> it "responds to the event" (
        Markup.observeElement
          |> Markup.query << by [ id "my-message" ]
          |> expect (isSomethingWhere <| Markup.text <| equals "You wrote: MOUSE UP!")
      )
    )
  , scenario "no element targeted for mouse up" (
      given (
        testSubject
      )
      |> when "a mouse up event occurs but no element is targeted"
        [ Event.mouseUp
        ]
      |> itShouldHaveFailedAlready
    )
  , scenario "view re-renders before mouseUp event" (
      given (
        testSubjectWithConditionalElement <|
          { on = [ Html.div [ Attr.id "conditional", Events.onMouseUp ConditionalTrigger ] [] ]
          , off = []
          }
      )
      |> when "mouse up in the conditional area"
        [ Markup.target << by [ id "conditional" ]
        , Event.mouseUp
        , Event.mouseUp
        , Event.mouseUp
        ]
      |> itShouldHaveFailedAlready
    )
  ]


mouseMoveInSpec : Spec Model Msg
mouseMoveInSpec =
  Spec.describe "mouse move in"
  [ scenario "it triggers mouseOver and mouseEnter events" (
      given (
        testSubject
      )
      |> when "the mouse moves into the element"
        [ Markup.target << by [ id "move-area" ]
        , Event.mouseMoveIn
        ]
      |> observeThat
        [ it "triggers a mouseOver event, which bubbles" (
            Observer.observeModel .mouseOver
              |> expect (equals 2)
          )
        , it "triggers a mouseEnter event, which does not bubble" (
            Observer.observeModel .mouseEnter
              |> expect (equals 1)
          )
        ]
    )
  , eventStepFailsWhenNoElementTargeted Event.mouseMoveIn
  , eventStepFailsWhenDocumentTargeted Event.mouseMoveIn
  , scenario "view re-renders before mouseMoveIn event" (
      given (
        testSubjectWithConditionalElement <|
          { on = [ Html.div [ Attr.id "conditional", Events.onMouseOver ConditionalTrigger ] [] ]
          , off = []
          }
      )
      |> when "mouse moves into the conditional area"
        [ Markup.target << by [ id "conditional" ]
        , Event.mouseMoveIn
        , Event.mouseMoveIn
        , Event.mouseMoveIn
        ]
      |> itShouldHaveFailedAlready
    )
  ]


mouseMoveOutSpec : Spec Model Msg
mouseMoveOutSpec =
  Spec.describe "mouse move out"
  [ scenario "it triggers mouseOut and mouseLeave events" (
      given (
        testSubject
      )
      |> when "the mouse moves out of the element"
        [ Markup.target << by [ id "move-area" ]
        , Event.mouseMoveOut
        ]
      |> observeThat
        [ it "triggers a mouseOut event, which bubbles" (
            Observer.observeModel .mouseOut
              |> expect (equals 2)
          )
        , it "triggers a mouseLeave event, which does not bubble" (
            Observer.observeModel .mouseLeave
              |> expect (equals 1)
          )
        ]
    )
  , eventStepFailsWhenNoElementTargeted Event.mouseMoveOut
  , eventStepFailsWhenDocumentTargeted Event.mouseMoveOut
  , scenario "view re-renders before mouseMoveOut event" (
      given (
        testSubjectWithConditionalElement <|
          { on = [ Html.div [ Attr.id "conditional", Events.onMouseOut ConditionalTrigger ] [] ]
          , off = []
          }
      )
      |> when "mouse moves out of the conditional area"
        [ Markup.target << by [ id "conditional" ]
        , Event.mouseMoveOut
        , Event.mouseMoveOut
        , Event.mouseMoveOut
        ]
      |> itShouldHaveFailedAlready
    )
  ]


customEventSpec : Spec Model Msg
customEventSpec =
  Spec.describe "program that uses a custom event"
  [ scenario "trigger a custom event" (
      given (
        testSubject
      )
      |> when "some event is triggered"
        [ Markup.target << by [ id "my-typing-place" ]
        , keyUpEvent 65
        , keyUpEvent 66
        , keyUpEvent 67
        ]
      |> it "does what it should" (
        Markup.observeElement
          |> Markup.query << by [ id "my-message" ]
          |> expect (isSomethingWhere <| Markup.text <| equals "You wrote: ABC!")
      )
    )
  , scenario "no element targeted for custom event" (
      given (
        testSubject
      )
      |> when "some event is triggered without targeting an element first"
        [ keyUpEvent 65
        ]
      |> itShouldHaveFailedAlready
    )
  , scenario "view re-renders before event" (
      given (
        testSubjectWithConditionalElement <|
          { on = [ Html.input [ Attr.id "conditional", onKeyUp (always ConditionalTrigger) ] [] ]
          , off = []
          }
      )
      |> when "type in the conditional input"
        [ Markup.target << by [ id "conditional" ]
        , keyUpEvent 65
        , keyUpEvent 66
        , keyUpEvent 67
        ]
      |> itShouldHaveFailedAlready
    )
  ]


noHandlerSpec : Spec Model Msg
noHandlerSpec =
  describe "no handlers"
  [ scenario "no click handler" (
      given (
        testSubject
      )
      |> when "it clicks an element without a click handler"
        [ Markup.target << by [ id "my-message" ]
        , Event.click
        ]
      |> when "it inputs but there's no input handler"
        [ Markup.target << by [ id "my-message" ]
        , Event.input "Hey!"
        ]
      |> when "it does a custom event but there's no handler"
        [ Markup.target << by [ id "my-message" ]
        , Event.trigger "unknown-event" <| Encode.object []
        ]
      |> it "does nothing" (
        Markup.observeElement
          |> Markup.query << by [ id "my-message" ]
          |> expect (isSomethingWhere <| Markup.text <| equals "You wrote: !")
      )
    )
  ]


eventStepFailsWhenNoElementTargeted =
  Specs.EventHelpers.eventStepFailsWhenNoElementTargeted testSubject


eventStepFailsWhenDocumentTargeted =
  Specs.EventHelpers.eventStepFailsWhenDocumentTargeted testSubject


testSubjectWithConditionalElement elementSwitch =
  Setup.initWithModel { message = "", count = 0, mouseUp = 0, mouseDown = 0, mouseEnter = 0, mouseOver = 0, mouseOut = 0, mouseLeave = 0, conditionalTriggerCount = 0 }
    |> Setup.withUpdate testUpdate
    |> Setup.withView (testView elementSwitch)


testSubject =
  testSubjectWithConditionalElement <| 
    { on = []
    , off = []
    }


keyUpEvent : Int -> Step.Context model -> Step.Command msg
keyUpEvent code =
  Encode.object
    [ ( "keyCode", Encode.int code )
    ]
    |> Event.trigger "keyup"


type alias ElementSwitch =
  { on: List (Html Msg)
  , off: List (Html Msg)
  }


type Msg
  = GotKey Int
  | HandleClick
  | HandleMegaClick
  | MouseDown
  | MouseUp
  | MouseOver
  | MouseEnter
  | MouseOut
  | MouseLeave
  | DoubleClick
  | ConditionalTrigger


type alias Model =
  { message: String
  , mouseUp: Int
  , mouseDown: Int
  , mouseOver: Int
  , mouseEnter: Int
  , mouseOut: Int
  , mouseLeave: Int
  , count: Int
  , conditionalTriggerCount: Int
  }


testUpdate : Msg -> Model -> (Model, Cmd Msg)
testUpdate msg model =
  case msg of
    HandleClick ->
      ( { model | count = model.count + 1 }, Cmd.none )
    ConditionalTrigger ->
      ( { model | conditionalTriggerCount = model.conditionalTriggerCount + 1 }, Cmd.none )
    HandleMegaClick ->
      ( { model | count = model.count * 10 }, Cmd.none )
    DoubleClick ->
      ( { model | message = "DOUBLE CLICK" }, Cmd.none )
    MouseDown ->
      ( { model | mouseDown = model.mouseDown + 1, message = "MOUSE DOWN" }, Cmd.none )
    MouseUp ->
      ( { model | mouseUp = model.mouseUp + 1, message = "MOUSE UP" }, Cmd.none )
    MouseOut ->
      ( { model | mouseOut = model.mouseOut + 1 }, Cmd.none )
    MouseLeave ->
      ( { model | mouseLeave = model.mouseLeave + 1 }, Cmd.none )
    MouseEnter ->
      ( { model | mouseEnter = model.mouseEnter + 1 }, Cmd.none )
    MouseOver ->
      ( { model | mouseOver = model.mouseOver + 1 }, Cmd.none )
    GotKey key ->
      let
        letter =
          Char.fromCode key
            |> String.fromChar
      in
        ( { model | message = model.message ++ letter }, Cmd.none )


testView : ElementSwitch -> Model -> Html Msg
testView elementSwitch model =
  Html.div [] <|
  [ Html.input [ Attr.id "my-typing-place", onKeyUp GotKey ] []
  , Html.button [ Attr.id "my-button", Events.onClick HandleClick, Events.onMouseUp MouseUp, Events.onMouseDown MouseDown ] [ Html.text "Click me!" ]
  , Html.button [ Attr.id "another-button", Events.onClick HandleMegaClick ] [ Html.text "No, Click me!" ]
  , Html.div [ Attr.id "tap-twice-area", Events.onMouseDown MouseDown, Events.onMouseUp MouseUp, Events.onClick HandleClick, Events.onDoubleClick DoubleClick ] [ Html.text "Double click!" ]
  , Html.div [ Attr.id "tap-area", Events.onMouseDown MouseDown, Events.onMouseUp MouseUp ] [ Html.text "Tap Area!" ]
  , Html.div [ Events.onMouseOver MouseOver, Events.onMouseEnter MouseEnter, Events.onMouseOut MouseOut, Events.onMouseLeave MouseLeave ]
    [ Html.div [ Attr.id "move-area", Events.onMouseOver MouseOver, Events.onMouseEnter MouseEnter, Events.onMouseOut MouseOut, Events.onMouseLeave MouseLeave ] [ Html.text "Move Area!" ]
    ]
  , Html.div [ Attr.id "my-message" ] [ Html.text <| "You wrote: " ++ model.message ++ "!" ]
  , Html.div [ Attr.id "my-count" ] [ Html.text <| "The count is " ++ String.fromInt model.count ++ "!" ]
  ] ++ (conditionalElement elementSwitch model)


conditionalElement elementSwitch model =
  if model.conditionalTriggerCount == 1 then
    elementSwitch.off
  else
    elementSwitch.on


onKeyUp : (Int -> Msg) -> Html.Attribute Msg
onKeyUp tagger =
  Events.on "keyup" (Json.map tagger Events.keyCode)


selectSpec : String -> Maybe (Spec Model Msg)
selectSpec name =
  case name of
    "click" -> Just clickSpec
    "doubleClick" -> Just doubleClickSpec
    "custom" -> Just customEventSpec
    "mouseDown" -> Just mouseDownSpec
    "mouseUp" -> Just mouseUpSpec
    "mouseMoveIn" -> Just mouseMoveInSpec
    "mouseMoveOut" -> Just mouseMoveOutSpec
    "noHandler" -> Just noHandlerSpec
    _ -> Nothing


main =
  Runner.browserProgram selectSpec