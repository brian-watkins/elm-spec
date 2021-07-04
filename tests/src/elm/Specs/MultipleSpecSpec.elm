module Specs.MultipleSpecSpec exposing (..)

import Spec exposing (..)
import Spec.Setup as Setup
import Spec.Observer as Observer
import Runner as TestRunner
import Specs.Helpers exposing (..)


passingSpec : Spec Model Msg
passingSpec =
  Spec.describe "a fragment"
  [ scenario "the observation is valid" (
      given (
        Setup.initWithModel { count = 99 }
          |> Setup.withUpdate testUpdate
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
        Setup.initWithModel { count = 99 }
          |> Setup.withUpdate testUpdate
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
        Setup.initWithModel { count = 108 }
          |> Setup.withUpdate testUpdate
      )
      |> it "contains the expected value" (
          Observer.observeModel .count
            |> expect (equals 108)
      )
    )
  , scenario "failing" (
      given (
        Setup.initWithModel { count = 108 }
          |> Setup.withUpdate testUpdate
      )
      |> it "contains a different value" (
          Observer.observeModel .count
            |> expect (equals 94)
      )
    )
  ]


testUpdate : Msg -> Model -> ( Model, Cmd Msg )
testUpdate _ model =
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