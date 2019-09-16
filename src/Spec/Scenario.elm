module Spec.Scenario exposing
  ( Scenario
  , scenario
  , when
  , it
  , describing
  )

import Spec.Subject as Subject exposing (Subject)
import Spec.Step as Step exposing (Step)
import Spec.Observation exposing (Observation, Expectation)


type alias Scenario model msg =
  { describing: String
  , subject: Subject model msg
  , steps: List (Step model msg)
  , observations: List (Observation model)
  }


scenario : String -> Subject model msg -> Scenario model msg
scenario description specSubject =
  { describing = ""
  , subject = specSubject
  , steps = 
      [ Step.build (formatScenarioDescription description) <|
          \_ ->
            Step.sendCommand specSubject.initialCommand
      ]
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
