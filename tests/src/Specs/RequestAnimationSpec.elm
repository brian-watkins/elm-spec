module Specs.RequestAnimationSpec exposing (main)

import Spec exposing (..)
import Spec.Setup as Setup
import Spec.Observer as Observer
import Spec.Claim exposing (..)
import Spec.Markup as Markup
import Spec.Markup.Selector exposing (..)
import Spec.Markup.Event as Event
import Spec.Navigator as Navigator
import Spec.Command
import Spec.Time
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Browser.Dom
import Browser.Events
import Task
import Process
import Time
import Runner
import Specs.Helpers exposing (..)


onAnimationFrameSpec : Spec Model Msg
onAnimationFrameSpec =
  describe "programs that needs to wait for the next animation frame"
  [ scenario "subscribed to onAnimationFrame and program triggers command that waits for next frame" (
      given (
        Setup.initWithModel testModel
          |> Setup.withView testView
          |> Setup.withUpdate testUpdate
          |> Setup.withSubscriptions testSubscriptions
          |> Spec.Time.allowExtraAnimationFrames
      )
      |> when "the second animation frame sub is triggered, and first setViewport and focus commands complete"
        [ Spec.Time.nextAnimationFrame
        ]
      |> when "the third animation frame sub is triggered, and second setViewport and focus commands complete, and first blur"
        [ Spec.Time.nextAnimationFrame
        ]
      |> when "the fourth animation frame sub is triggered, third setViewport and focus occur, and the second blur command completes"
        [ Spec.Time.nextAnimationFrame
        ]
      |> observeThat
        [ it "focuses the element twice" (
            Observer.observeModel .focus
              |> expect (equals 3)
          )
        , it "records the loops" (
            Observer.observeModel .loops
              |> expect (equals 4)
          )
        , it "updates the viewport three times" (
            Navigator.observe
              |> expect (Navigator.viewportOffset <| specifyThat .y <| equals 30)
          )
        ]
    )
  ]


minimalAnimationFrameSpec : Spec Model Msg
minimalAnimationFrameSpec =
  describe "minimal onAnimationFrame subscription example"
  [ scenario "steps that log animation frame warning" (
      given (
        Setup.initWithModel testModel
          |> Setup.withView testView
          |> Setup.withUpdate minimalUpdate
          |> Setup.withSubscriptions minimalSubscriptions
          |> Spec.Time.allowExtraAnimationFrames
      )
      |> when "second animation frame loop occurs and first getElement"
        [ Spec.Time.nextAnimationFrame
        ]
      |> when "third animation frame loop occurs and second getElement"
        [ Spec.Command.send Cmd.none
        ]
      |> observeThat
        [ it "updates the model" (
            Observer.observeModel .loops
              |> expect (equals 3)
          )
        , it "gets the elements" (
            Observer.observeModel .elements
              |> expect (isListWithLength 2)
          )
        ]
    )
  ]


failingAnimationFrameSpec : Spec Model Msg
failingAnimationFrameSpec =
  describe "failing onAnimationFrame subscription example"
  [ scenario "steps that trigger extra animation frame tasks" (
      given (
        Setup.initWithModel testModel
          |> Setup.withView testView
          |> Setup.withUpdate minimalUpdate
          |> Setup.withSubscriptions minimalSubscriptions
      )
      |> when "second animation frame loop occurs and first getElement"
        [ Spec.Time.nextAnimationFrame
        ]
      |> when "third animation frame loop occurs and second getElement"
        [ Spec.Command.send Cmd.none
        ]
      |> observeThat
        [ it "updates the model" (
            Observer.observeModel .loops
              |> expect (equals 3)
          )
        , it "gets the elements" (
            Observer.observeModel .elements
              |> expect (isListWithLength 2)
          )
        ]
    )
  ]


noUpdateSpec : Spec Model Msg
noUpdateSpec =
  describe "nextAnimationFrame"
  [ scenario "nextAnimationFrame does not trigger any update" (
      given (
        Setup.initWithModel testModel 
          |> Setup.withView testView
          |> Setup.withUpdate minimalUpdate
      )
      |> when "animation frame is triggered"
        [ Spec.Time.nextAnimationFrame
        ]
      |> observeThat
        [ it "does not change the model" (
            Observer.observeModel .loops
              |> expect (equals 0)
          )
        , it "renders the view" (
            Markup.observeElement
              |> Markup.query << by [ id "focus-element" ]
              |> expect isSomething
          )
        ]
    )
  ]


domUpdateSpec : Spec Model Msg
domUpdateSpec =
  describe "dom updates"
  [ scenario "multiple dom updates in one task" (
      given (
        Setup.initWithModel testModel
          |> Setup.withUpdate domUpdate
          |> Setup.withView domView
          |> Spec.Time.allowExtraAnimationFrames
      )
      |> when "the command is triggered"
        [ Markup.target << by [ tag "button" ]
        , Event.click
        , Spec.Time.nextAnimationFrame
        ]
      |> it "updates the viewport" (
        Navigator.observe
          |> expect (Navigator.viewportOffset <| equals { x = 0, y = 46 })
      )
    )
  ]


someFailureSpec : Spec Model Msg
someFailureSpec =
  describe "failure after allowed in previous scenario"
  [ scenario "extra animation frames but allowed" (
      given (
        Setup.initWithModel testModel
          |> Setup.withUpdate minimalUpdate
          |> Setup.withView testView
          |> Setup.withSubscriptions minimalSubscriptions
          |> Spec.Time.allowExtraAnimationFrames
      )
      |> when "an animation frame occurs"
        [ Spec.Time.nextAnimationFrame
        ]
      |> it "updates the model" (
        Observer.observeModel .loops
          |> expect (equals 2)
      )
    )
  , scenario "another scenario that does not allow extra animation frames" (
      given (
        Setup.initWithModel testModel
          |> Setup.withUpdate minimalUpdate
          |> Setup.withView domView
          |> Setup.withSubscriptions minimalSubscriptions
      )
      |> when "an animation frame occurs"
        [ Spec.Time.nextAnimationFrame
        ]
      |> it "updates the model" (
        Observer.observeModel .loops
          |> expect (equals 2)
      )
    )
  ]


multipleScenariosSpec : Spec Model Msg
multipleScenariosSpec =
  describe "multiple scenarios with extra animation frames"
  [ scenario "first" (
      given (
        Setup.initWithModel testModel
          |> Setup.withUpdate minimalUpdate
          |> Setup.withView testView
          |> Setup.withSubscriptions minimalSubscriptions
          |> Spec.Time.allowExtraAnimationFrames
      )
      |> when "an animation frame occurs"
        [ Spec.Time.nextAnimationFrame
        ]
      |> observeThat
        [ it "updates the model" (
            Observer.observeModel .elements
              |> expect (isListWithLength 1)
          )
        ]
    )
  , scenario "second" (
      given (
        Setup.initWithModel testModel
          |> Setup.withUpdate minimalUpdate
          |> Setup.withView testView
          |> Setup.withSubscriptions minimalSubscriptions
          |> Spec.Time.allowExtraAnimationFrames
      )
      |> when "an animation frame occurs"
        [ Spec.Time.nextAnimationFrame
        ]
      |> observeThat
        [ it "updates the model" (
            Observer.observeModel .elements
              |> expect (isListWithLength 1)
          )
        ]
    )
  ]


type alias Model =
  { loops: Int
  , focus: Int
  , elements: List Browser.Dom.Element
  }


testModel =
  { loops = 0
  , focus = 0
  , elements = []
  }


type Msg
  = OnAnimationFrame
  | DidFocus
  | DoNothing
  | DoSomething
  | DidSetViewport
  | GotElement (Result Browser.Dom.Error Browser.Dom.Element)


testView : Model -> Html Msg
testView model =
  Html.div []
  [ Html.input [ Attr.id "focus-element", Events.onFocus DidFocus ] []
  ]


domView : Model -> Html Msg
domView model =
  Html.div []
  [ Html.button [ Events.onClick DoSomething ] [ Html.text "Click me!" ]
  , Html.div
    [ Attr.id "test-element"
    , Attr.style "position" "absolute"
    , Attr.style "top" "56"
    , Attr.style "left" "20"
    ]
    [ Html.text "TEST!" ]
  ]


domUpdate : Msg -> Model -> (Model, Cmd Msg)
domUpdate msg model =
  case msg of
    DoSomething ->
      ( model
      , Browser.Dom.getElement "test-element"
          |> Task.andThen (\element ->
            Browser.Dom.setViewport 0.0 (element.element.y - 10.0)
          )
          |> Task.attempt (\_ -> DoNothing)
      )
    _ ->
      ( model, Cmd.none )


minimalUpdate : Msg -> Model -> (Model, Cmd Msg)
minimalUpdate msg model =
  case msg of
    OnAnimationFrame ->
      ( { model | loops = model.loops + 1 }
      , Browser.Dom.getElement "focus-element"
          |> Task.attempt GotElement
      )
    GotElement result ->
      case result of
        Ok element ->
          ( { model | elements = element :: model.elements }, Cmd.none )
        Err _ ->
          ( model, Cmd.none )
    _ ->
      ( model, Cmd.none )


testUpdate : Msg -> Model -> (Model, Cmd Msg)
testUpdate msg model =
  case msg of
    OnAnimationFrame ->
      let
        frames = model.loops + 1
      in
      ( { model | loops = frames }
      , Cmd.batch
        [ Browser.Dom.setViewport 0 (toFloat frames * 10)
            |> Task.perform (\_ -> DidSetViewport)
        , if frames == 1 then
            Process.sleep 1000
              |> Task.andThen (\_ -> Task.succeed ())
              |> Task.perform (\_ -> DoNothing)
          else
            Cmd.none
        , Browser.Dom.focus "focus-element"
            |> Task.attempt (\_ -> DoNothing)
        ]
      )
    DidFocus ->
      ( { model | focus = model.focus + 1 }
      , Browser.Dom.blur "focus-element"
          |> Task.attempt (\_ -> DoNothing)
      )
    _ ->
      ( model, Cmd.none )


testSubscriptions : Model -> Sub Msg
testSubscriptions model =
  Sub.batch
    [ Browser.Events.onAnimationFrame (\_ -> OnAnimationFrame)
    , Time.every 2000 (\_ -> DoNothing)
    ]


minimalSubscriptions : Model -> Sub Msg
minimalSubscriptions model =
  Browser.Events.onAnimationFrame (\_ -> OnAnimationFrame)


selectSpec : String -> Maybe (Spec Model Msg)
selectSpec name =
  case name of
    "onFrame" -> Just onAnimationFrameSpec
    "minimal" -> Just minimalAnimationFrameSpec
    "noUpdate" -> Just noUpdateSpec
    "domUpdate" -> Just domUpdateSpec
    "someFailure" -> Just someFailureSpec
    "multipleScenarios" -> Just multipleScenariosSpec
    "fail" -> Just failingAnimationFrameSpec
    _ -> Nothing


main =
  Runner.browserProgram selectSpec

