module Spec.Scenario.Internal exposing
  ( Spec(..), Scenario, ScenarioAction, ScenarioPlan, Observation, Step
  , buildStep
  , buildObservation
  , describing
  , formatScenarioDescription
  , formatCondition
  )

import Spec.Subject.Internal exposing (SubjectProvider)
import Spec.Step exposing (Context, Command)
import Spec.Message exposing (Message)
import Spec.Observer exposing (Expectation)


type Spec model msg
  = Spec (List (Scenario model msg))


type alias Scenario model msg =
  { specification: String
  , description: String
  , subjectProvider: SubjectProvider model msg
  , steps: List (Step model msg)
  , observations: List (Observation model)
  , tags: List String
  }


type alias ScenarioAction model msg =
  { subjectProvider: SubjectProvider model msg
  , steps: List (Step model msg)
  }


type alias ScenarioPlan model msg =
  { subjectProvider: SubjectProvider model msg
  , steps: List (Step model msg)
  , observations: List (Observation model)
  }


type alias Observation model =
  { description: String
  , expectation: Expectation model
  }


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
