module Specs.InitWorkerSpec exposing (..)

import Spec exposing (Spec)
import Spec.Subject as Subject
import Spec.Scenario exposing (..)
import Spec.Observer as Observer
import Spec.Observation as Observation
import Runner
import Task


usesModelFromInitSpec : Spec Model Msg
usesModelFromInitSpec =
  Spec.describe "a worker"
  [ scenario "Uses Model from Init" (
      given (
        Subject.init testInit
          |> Subject.withUpdate testUpdate
      )
      |> it "uses the given model" (
        Observation.selectModel
          |> Observation.mapSelection .count
          |> Observation.expect (Observer.isEqual 41)
      )
    )
  ]


usesCommandFromInitSpec : Spec Model Msg
usesCommandFromInitSpec =
  Spec.describe "a worker"
  [ scenario "Uses command from Init" (
      given (
        Subject.init (testInitWithCommand 33)
          |> Subject.withUpdate testUpdate
      )
      |> it "updates the model" (
        Observation.selectModel
          |> Observation.mapSelection .count
          |> Observation.expect (Observer.isEqual 33)
      )
    )
  ]


testUpdate : Msg -> Model -> ( Model, Cmd Msg )
testUpdate msg model =
  case msg of
    UpdateCount count ->
      ( { model | count = count }, Cmd.none )


testInit : ( Model, Cmd Msg )
testInit =
  ( { count = 41 }, Cmd.none )


testInitWithCommand : Int -> ( Model, Cmd Msg )
testInitWithCommand number =
  ( { count = 0 }
  , Task.succeed number |> Task.perform UpdateCount
  )


selectSpec : String -> Maybe (Spec Model Msg)
selectSpec name =
  case name of
    "modelNoCommandInit" -> Just usesModelFromInitSpec
    "modelAndCommandInit" -> Just usesCommandFromInitSpec
    _ -> Nothing


type Msg
  = UpdateCount Int


type alias Model =
  { count: Int
  }


main =
  Runner.program selectSpec