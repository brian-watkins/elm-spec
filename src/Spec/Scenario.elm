module Spec.Scenario exposing
  ( Scenario
  , scenario
  , when
  , it
  , describing
  )

import Spec.Subject as Subject exposing (SubjectGenerator)
import Spec.Step as Step exposing (Step)
import Spec.Observation exposing (Observation, Expectation)


type alias Scenario model msg =
  { describing: String
  , description: String
  , subjectGenerator: SubjectGenerator model msg
  , steps: List (Step model msg)
  , observations: List (Observation model)
  }


scenario : String -> SubjectGenerator model msg -> Scenario model msg
scenario description subjectGenerator =
  { describing = ""
  , description = formatScenarioDescription description
  , subjectGenerator = subjectGenerator
  , steps = []
  , observations = []
  }


when : String -> List (Step.Context model -> Step.Command msg) -> Scenario model msg -> Scenario model msg
when condition messageSteps scenarioData =
  { scenarioData
  | steps =
      messageSteps
        |> List.map (Step.build <| formatCondition condition)
        |> List.append scenarioData.steps
  }


it : String -> Expectation model -> Scenario model msg -> Scenario model msg
it description expectation scenarioData =
  { scenarioData
  | observations = List.append scenarioData.observations
      [ { description = formatObservationDescription description
        , expectation = expectation
        }
      ]
  }


describing : String -> Scenario model msg -> Scenario model msg
describing description scenarioData =
  { scenarioData | describing = formatSpecDescription description }


formatSpecDescription : String -> String
formatSpecDescription description =
  "Describing: " ++ description


formatScenarioDescription : String -> String
formatScenarioDescription description =
  "Scenario: " ++ description


formatCondition : String -> String
formatCondition condition =
  "When " ++ condition


formatObservationDescription : String -> String
formatObservationDescription description =
  "It " ++ description
