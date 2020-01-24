module Spec.Scenario.Internal exposing
  ( Spec(..), Scenario, Script, Plan, Observation, Step
  , Expectation(..), Judgment(..)
  , buildStep
  , buildObservation
  , describing
  , formatScenarioDescription
  , formatCondition
  )

import Spec.Setup.Internal exposing (Setup)
import Spec.Step exposing (Context, Command)
import Spec.Message exposing (Message)
import Spec.Claim exposing (Verdict)


type Spec model msg
  = Spec (List (Scenario model msg))


type alias Scenario model msg =
  { specification: String
  , description: String
  , setup: Setup model msg
  , steps: List (Step model msg)
  , observations: List (Observation model)
  , tags: List String
  }


type alias Script model msg =
  { setup: Setup model msg
  , steps: List (Step model msg)
  }


type alias Plan model msg =
  { setup: Setup model msg
  , steps: List (Step model msg)
  , observations: List (Observation model)
  }


type alias Observation model =
  { description: String
  , expectation: Expectation model
  }


type Expectation model =
  Expectation
    (Context model -> Judgment model)


type Judgment model
  = Complete Verdict
  | Inquire Message (Message -> Judgment model)


type alias Step model msg =
  { run: Context model -> Command msg
  , condition: String
  }


buildStep : String -> (Context model -> Command msg) -> Step model msg
buildStep description stepper =
  { run = stepper
  , condition = description
  }


buildObservation : String -> Expectation model -> Observation model
buildObservation description expectation =
  { description = formatObservationDescription description
  , expectation = expectation
  }


describing : String -> Scenario model msg -> Scenario model msg
describing description scenarioData =
  { scenarioData | specification = formatSpecDescription description }


formatSpecDescription : String -> String
formatSpecDescription description =
  description


formatScenarioDescription : String -> String
formatScenarioDescription description =
  "Scenario: " ++ description


formatCondition : String -> String
formatCondition condition =
  "When " ++ condition


formatObservationDescription : String -> String
formatObservationDescription description =
  "It " ++ description
