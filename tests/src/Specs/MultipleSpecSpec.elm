module Specs.MultipleSpecSpec exposing (..)

import Spec exposing (Spec)
import Spec.Message exposing (Message)
import Spec.Subject as Subject
import Spec.Scenario exposing (..)
import Spec.Observer as Observer
import Spec.Observation as Observation
import Runner as TestRunner
import Json.Encode as Encode
import Json.Decode as Json


passingSpec : Spec Model Msg
passingSpec =
  Spec.describe "a fragment"
  [ scenario "the observation is valid" (
      given (
        Subject.initWithModel { count = 99 }
          |> Subject.withUpdate testUpdate
      )
      |> it "contains the expected value" (
          Observation.selectModel
            |> Observation.mapSelection .count
            |> Observation.expect (Observer.isEqual 99)
      )
    )
  ]


failingSpec : Spec Model Msg
failingSpec =
  Spec.describe "another fragment"
  [ scenario "the observation is invalid" (
      given (
        Subject.initWithModel { count = 99 }
          |> Subject.withUpdate testUpdate
      )
      |> it "contains the expected value" (
          Observation.selectModel
            |> Observation.mapSelection .count
            |> Observation.expect (Observer.isEqual 76)
      )
    )
  ]


specWithAScenario : Spec Model Msg
specWithAScenario =
  Spec.describe "a third fragment"
  [ scenario "passing" (
      given (
        Subject.initWithModel { count = 108 }
          |> Subject.withUpdate testUpdate
      )
      |> it "contains the expected value" (
          Observation.selectModel
            |> Observation.mapSelection .count
            |> Observation.expect (Observer.isEqual 108)
      )
    )
  , scenario "failing" (
      given (
        Subject.initWithModel { count = 108 }
          |> Subject.withUpdate testUpdate
      )
      |> it "contains a different value" (
          Observation.selectModel
            |> Observation.mapSelection .count
            |> Observation.expect (Observer.isEqual 94)
      )
    )
  ]


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