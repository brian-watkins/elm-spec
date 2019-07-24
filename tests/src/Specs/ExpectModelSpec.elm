module Specs.ExpectModelSpec exposing (..)

import Spec exposing (Spec)
import Observer
import Runner


failingSpec : Spec Model Msg
failingSpec =
  Spec.given { count = 99 } testUpdate
    |> Spec.expectModel (\model -> 
      Observer.isEqual 17 model.count
    )

passingSpec : Spec Model Msg
passingSpec =
  Spec.given { count = 99 } testUpdate
    |> Spec.expectModel (\model -> 
      Observer.isEqual 99 model.count
    )


testUpdate : Msg -> Model -> ( Model, Cmd Msg )
testUpdate msg model =
  ( model, Cmd.none )


selectSpec : String -> Spec Model Msg
selectSpec specName =
  case specName of
    "failing" ->
      failingSpec
    "passing" ->
      passingSpec
    _ ->
      failingSpec


type Msg
  = Msg


type alias Model =
  { count: Int
  }


main =
  Runner.program selectSpec