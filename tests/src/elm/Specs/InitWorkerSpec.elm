module Specs.InitWorkerSpec exposing (..)

import Spec exposing (..)
import Spec.Setup as Setup
import Spec.Observer as Observer
import Runner
import Task
import Specs.Helpers exposing (..)


usesModelFromInitSpec : Spec Model Msg
usesModelFromInitSpec =
  Spec.describe "a worker"
  [ scenario "Uses Model from Init" (
      given (
        Setup.init testInit
          |> Setup.withUpdate testUpdate
      )
      |> it "uses the given model" (
        Observer.observeModel .count
          |> expect (equals 41)
      )
    )
  ]


usesCommandFromInitSpec : Spec Model Msg
usesCommandFromInitSpec =
  Spec.describe "a worker"
  [ scenario "Uses command from Init" (
      given (
        Setup.init (testInitWithCommand 33)
          |> Setup.withUpdate testUpdate
      )
      |> it "updates the model" (
        Observer.observeModel .count
          |> expect (equals 33)
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