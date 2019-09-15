module Spec.Scenario exposing
  ( Scenario
  , scenario
  , when
  , it
  , addCondition
  )

import Spec.Subject as Subject exposing (Subject)
import Spec.Step as Step exposing (Step)
import Spec.Observation exposing (Observation, Expectation)


type alias Scenario model msg =
  { subject: Subject model msg
  , steps: List (Step model msg)
  , observations: List (Observation model)
  }


scenario : String -> Subject model msg -> Scenario model msg
scenario description specSubject =
  { subject = specSubject
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


addCondition : String -> Scenario model msg -> Scenario model msg
addCondition condition scenarioData =
  let
    subject = scenarioData.subject
  in
    { scenarioData
    | subject = { subject | conditions = subject.conditions ++ [ condition ] }
    }


formatScenarioDescription : String -> String
formatScenarioDescription description =
  "Scenario: " ++ description


formatCondition : String -> String
formatCondition condition =
  "When " ++ condition


formatObservationDescription : String -> String
formatObservationDescription description =
  "It " ++ description
