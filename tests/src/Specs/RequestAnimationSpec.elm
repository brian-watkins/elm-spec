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
      |> when "the animation frame updates three times"
        [ Spec.Time.nextAnimationFrame
        , Spec.Time.nextAnimationFrame
        , Spec.Time.nextAnimationFrame
        ]
      |> observeThat
        [ it "updates the viewport three times" (
            Navigator.observe
              |> expect (Navigator.viewportOffset <| require .y <| equals 30)
          )
        , it "focuses the element three times" (
            Observer.observeModel .focus
              |> expect (equals 3)
          )
        ]
    )
  ]


type alias Model =
  { loops: Int
  , focus: Int
  }


testModel =
  { loops = 0
  , focus = 0
  }


type Msg
  = OnAnimationFrame
  | DidFocus
  | DoNothing


testView : Model -> Html Msg
testView model =
  Html.div []
  [ Html.input [ Attr.id "focus-element", Events.onFocus DidFocus ] []
  ]


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
            |> Task.perform (\_ -> DoNothing)
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
    _ -> Nothing


main =
  Runner.browserProgram selectSpec

