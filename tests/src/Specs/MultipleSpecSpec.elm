module Specs.MultipleSpecSpec exposing (..)

import Spec exposing (Spec)
import Spec.Message exposing (Message)
import Spec.Subject as Subject
import Spec.Observer as Observer
import Spec.Actual as Actual
import Runner as TestRunner
import Json.Encode as Encode
import Json.Decode as Json


passingSpec : Spec Model Msg
passingSpec =
  Spec.given "a fragment" (
    Subject.initWithModel { count = 99 }
      |> Subject.withUpdate testUpdate
  )
  |> Spec.it "contains the expected value" (
      Actual.model
        |> Actual.map .count
        |> Spec.expect (Observer.isEqual 99)
  )


failingSpec : Spec Model Msg
failingSpec =
  Spec.given "another fragment" (
    Subject.initWithModel { count = 99 }
      |> Subject.withUpdate testUpdate
  )
  |> Spec.it "contains the expected value" (
      Actual.model
        |> Actual.map .count
        |> Spec.expect (Observer.isEqual 76)
  )


specWithAScenario : Spec Model Msg
specWithAScenario =
  Spec.given "a third fragment" (
    Subject.initWithModel { count = 108 }
      |> Subject.withUpdate testUpdate
  )
  |> Spec.it "contains the expected value" (
      Actual.model
        |> Actual.map .count
        |> Spec.expect (Observer.isEqual 108)
  )
  |> Spec.suppose (
    Spec.given "another scenario"
      >> Spec.it "contains a different value" (
        Actual.model
          |> Actual.map .count
          |> Spec.expect (Observer.isEqual 94)
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