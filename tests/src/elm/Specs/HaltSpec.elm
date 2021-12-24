module Specs.HaltSpec exposing (main)

import Spec exposing (..)
import Spec.Setup as Setup
import Spec.Step as Step
import Spec.Report as Report
import Specs.Helpers exposing (..)
import Runner

haltScenarioSpec : Spec Model Msg
haltScenarioSpec =
  Spec.describe "halt a scenario"
  [ scenario "a step halts the scenario" (
      given (
        Setup.initWithModel { count = 7 }
      )
      |> when "the scenario is halted"
        [ \_ -> Step.halt <| Report.note "You told me to stop!!?"
        ]
      |> itShouldHaveFailedAlready
    )
  ]


type alias Model =
  { count: Int
  }


type Msg =
  Msg


selectSpec : String -> Maybe (Spec Model Msg)
selectSpec name =
  case name of
    "haltScenario" -> Just haltScenarioSpec
    _ -> Nothing


main =
  Runner.program selectSpec