module Specs.InitWorkerSpec exposing (..)

import Spec exposing (Spec)
import Spec.Subject as Subject
import Observer
import Runner
import Task


usesModelFromInitSpec : Spec Model Msg
usesModelFromInitSpec =
  Spec.given (
    Subject.worker (\_ -> testInit) testUpdate
  )
  |> Spec.when
    << Spec.nothing
  |> Spec.it "uses the given model" (
    Spec.expectModel <|
      \model ->
        Observer.isEqual 41 model.count
  )


usesCommandFromInitSpec : Spec Model Msg
usesCommandFromInitSpec =
  Spec.given (
    Subject.worker (\_ -> testInitWithCommand 33) testUpdate
  )
  |> Spec.when
    << Spec.nothing
  |> Spec.it "updates the model" (
    Spec.expectModel <|
      \model ->
        Observer.isEqual 33 model.count
  )


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


selectSpec : String -> Spec Model Msg
selectSpec name =
  case name of
    "modelNoCommandInit" ->
      usesModelFromInitSpec
    "modelAndCommandInit" ->
      usesCommandFromInitSpec
    _ ->
      usesModelFromInitSpec


type Msg
  = UpdateCount Int


type alias Model =
  { count: Int
  }


main =
  Runner.program selectSpec