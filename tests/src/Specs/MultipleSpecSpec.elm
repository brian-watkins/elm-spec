module Specs.MultipleSpecSpec exposing (..)

import Spec exposing (..)
import Spec.Runner
import Spec.Message exposing (Message)
import Spec.Subject as Subject
import Spec.Claim as Claim
import Spec.Observer as Observer
import Runner as TestRunner
import Json.Encode as Encode
import Json.Decode as Json
import Specs.Helpers exposing (..)


passingSpec : Spec Model Msg
passingSpec =
  Spec.describe "a fragment"
  [ scenario "the observation is valid" (
      given (
        Subject.initWithModel { count = 99 }
          |> Subject.withUpdate testUpdate
      )
      |> it "contains the expected value" (
          Observer.observeModel .count
            |> expect (equals 99)
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
          Observer.observeModel .count
            |> expect (equals 76)
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
          Observer.observeModel .count
            |> expect (equals 108)
      )
    )
  , scenario "failing" (
      given (
        Subject.initWithModel { count = 108 }
          |> Subject.withUpdate testUpdate
      )
      |> it "contains a different value" (
          Observer.observeModel .count
            |> expect (equals 94)
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
  Spec.Runner.program TestRunner.config
    [ passingSpec
    , failingSpec
    , specWithAScenario
    ]