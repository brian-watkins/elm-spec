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


viewSpec : Spec Model Msg
viewSpec =
  describe "update the view on animation frame"
  [ scenario "next animation frame triggers view update" (
      given (
        Setup.initWithModel testModel
          |> Setup.withUpdate minimalUpdate
          |> Setup.withView testView
          |> Setup.withSubscriptions testSubscriptions
          |> Spec.Time.allowExtraAnimationFrames
      )
      |> when "animation frames occur"
        [ Spec.Time.nextAnimationFrame
        , Spec.Time.nextAnimationFrame
        , Spec.Time.nextAnimationFrame
        ]
      |> it "updates the view" (
          Markup.observeElement
            |> Markup.query << by [ id "loops" ]
            |> expect (isSomethingWhere <| Markup.text <| equals "3 loops!")
        )
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
  [ scenario "dom update triggers a view update" (
      given (
        Setup.initWithModel testModel
          |> Setup.withUpdate domUpdate
          |> Setup.withView domView
      )
      |> when "the dom command is triggered"
        [ Markup.target << by [ id "fetch-button" ]
        , Event.click
        ]
      |> it "updates the view" (
        Markup.observeElement
          |> Markup.query << by [ id "fetched-elements" ]
          |> expect (isSomethingWhere <| Markup.text <| equals "1")
      )
    )
  , scenario "multiple dom updates in one task" (
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


inputSpec : Spec Model Msg
inputSpec =
  describe "input event and dom task"
  [ scenario "input event and dom task" (
      given (
        Setup.initWithModel testModel
          |> Setup.withUpdate domUpdate
          |> Setup.withView domView
      )
      |> when "the input occurs"
        [ Markup.target << by [ tag "input" ]
        , Event.input "Helloooo!"
        , Event.input "Cool!"
        ]
      |> observeThat
        [ it "updates the view" (
            Markup.observeElement
              |> Markup.query << by [ id "input-text" ]
              |> expect (isSomethingWhere <| Markup.text <| equals "Cool!")
          )
        , it "got the element" (
            Markup.observeElement
              |> Markup.query << by [ id "fetched-elements" ]
              |> expect (isSomethingWhere <| Markup.text <| equals "2")
          )
        ]
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
  , text: String
  }


testModel =
  { loops = 0
  , focus = 0
  , elements = []
  , text = ""
  }


type Msg
  = OnAnimationFrame
  | DidFocus
  | DoNothing
  | DoSomething
  | FetchElement
  | GotInput String
  | DidSetViewport
  | GotElement (Result Browser.Dom.Error Browser.Dom.Element)


testView : Model -> Html Msg
testView model =
  Html.div []
  [ Html.input [ Attr.id "focus-element", Events.onFocus DidFocus ] []
  , Html.div [ Attr.id "loops" ]
    [ Html.text <| String.fromInt model.loops ++ " loops!" ]
  ]


domView : Model -> Html Msg
domView model =
  Html.div []
  [ Html.button [ Events.onClick DoSomething ] [ Html.text "Click me!" ]
  , Html.button [ Attr.id "fetch-button", Events.onClick FetchElement ] [ Html.text "Fetch" ]
  , Html.div [ Attr.id "fetched-elements" ] [ Html.text <| String.fromInt <| List.length model.elements ]
  , Html.div
    [ Attr.id "test-element"
    , Attr.style "position" "absolute"
    , Attr.style "top" "56"
    , Attr.style "left" "20"
    ]
    [ Html.text "TEST!" ]
  , Html.input [ Events.onInput GotInput ] []
  , Html.div [ Attr.id "input-text" ] [ Html.text model.text ]
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
    FetchElement ->
      ( model
      , Browser.Dom.getElement "test-element"
          |> Task.attempt GotElement
      )
    GotElement elementResult ->
      case elementResult of
        Ok element ->
          ( { model | elements = element :: model.elements }, Cmd.none )
        Err _ ->
          ( model, Cmd.none )
    GotInput text ->
      ( { model | text = text }
      , Browser.Dom.getElement "test-element"
          |> Task.attempt GotElement
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
testSubscriptions _ =
  Sub.batch
    [ Browser.Events.onAnimationFrame (\_ -> OnAnimationFrame)
    , Time.every 2000 (\_ -> DoNothing)
    ]


minimalSubscriptions : Model -> Sub Msg
minimalSubscriptions _ =
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
    "view" -> Just viewSpec
    "input" -> Just inputSpec
    _ -> Nothing


main =
  Runner.browserProgram selectSpec

