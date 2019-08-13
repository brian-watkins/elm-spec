module Specs.MultipleSpecSpec exposing (..)

import Spec exposing (Spec)
import Spec.Message exposing (Message)
import Spec.Subject as Subject
import Runner as TestRunner
import Observer
import Json.Encode as Encode
import Json.Decode as Json


passingSpec : Spec Model Msg
passingSpec =
  Spec.given "a fragment" (
    Subject.initWithModel { count = 99 }
      |> Subject.withUpdate testUpdate
  )
  |> Spec.it "contains the expected value" (
      Spec.expectModel <|
        \model ->
          Observer.isEqual 99 model.count
  )


failingSpec : Spec Model Msg
failingSpec =
  Spec.given "another fragment" (
    Subject.initWithModel { count = 99 }
      |> Subject.withUpdate testUpdate
  )
  |> Spec.it "contains the expected value" (
      Spec.expectModel <|
        \model ->
          Observer.isEqual 76 model.count
  )


specWithAScenario : Spec Model Msg
specWithAScenario =
  Spec.given "a third fragment" (
    Subject.initWithModel { count = 108 }
      |> Subject.withUpdate testUpdate
  )
  |> Spec.it "contains the expected value" (
      Spec.expectModel <|
        \model ->
          Observer.isEqual 108 model.count
  )
  |> Spec.suppose (
    Spec.given "another scenario"
      >> Spec.it "contains a different value" (
        Spec.expectModel <|
          \model ->
            Observer.isEqual 94 model.count
      )
  )


testUpdate : Msg -> Model -> ( Model, Cmd Msg )
testUpdate msg model =
  ( model, Cmd.none )


type Msg
  = Msg


type alias Model =
  { count: Int
  }


main =
  Spec.program TestRunner.config
    [ passingSpec
    , failingSpec
    , specWithAScenario
    ]