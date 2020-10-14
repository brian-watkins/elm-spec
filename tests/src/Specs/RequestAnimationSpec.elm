module Specs.RequestAnimationSpec exposing (main)

import Spec exposing (..)
import Spec.Setup as Setup
import Spec.Observer as Observer
import Spec.Claim exposing (..)
import Spec.Markup as Markup
import Spec.Markup.Selector exposing (..)
import Spec.Markup.Event as Event
import Spec.Navigator as Navigator
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
  [ scenario "animation frames occur" (
      given (
        Setup.initWithModel testModel
          |> Setup.withView testView
          |> Setup.withUpdate minimalUpdate
          |> Setup.withSubscriptions (\_ -> Browser.Events.onAnimationFrame (\_ -> OnAnimationFrame))
      )
      |> when "second animation frame loop occurs and first getElement"
        [ Spec.Time.nextAnimationFrame
        ]
      |> observeThat
        [ it "updates the model" (
            Observer.observeModel .loops
              |> expect (equals 2)
          )
        , it "gets the element" (
            Observer.observeModel .element
              |> expect isSomething
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


type alias Model =
  { loops: Int
  , focus: Int
  , element: Maybe Browser.Dom.Element
  }


testModel =
  { loops = 0
  , focus = 0
  , element = Nothing
  }


type Msg
  = OnAnimationFrame
  | DidFocus
  | DoNothing
  | DidSetViewport
  | GotElement (Result Browser.Dom.Error Browser.Dom.Element)


testView : Model -> Html Msg
testView model =
  Html.div []
  [ Html.input [ Attr.id "focus-element", Events.onFocus DidFocus ] []
  ]


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
          ( { model | element = Just element }, Cmd.none )
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
    GotElement _ ->
      ( model, Cmd.none )
    DidSetViewport ->
      ( model, Cmd.none )
    DoNothing ->
      ( model, Cmd.none )


testSubscriptions : Model -> Sub Msg
testSubscriptions model =
  Sub.batch
    [ Browser.Events.onAnimationFrame (\_ -> OnAnimationFrame)
    , Time.every 2000 (\_ -> DoNothing)
    ]


selectSpec : String -> Maybe (Spec Model Msg)
selectSpec name =
  case name of
    "onFrame" -> Just onAnimationFrameSpec
    "minimal" -> Just minimalAnimationFrameSpec
    "noUpdate" -> Just noUpdateSpec
    _ -> Nothing


main =
  Runner.browserProgram selectSpec

