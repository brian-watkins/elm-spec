module Spec.Scenario exposing
  ( Scenario
  , ScenarioPlan
  , ScenarioAction
  , scenario
  , given
  , when
  , observeThat
  , it
  , describing
  , tagged
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
  , tags: List String
  }


type alias ScenarioAction model msg =
  { subjectGenerator: SubjectGenerator model msg
  , steps: List (Step model msg)
  }


type alias ScenarioPlan model msg =
  { subjectGenerator: SubjectGenerator model msg
  , steps: List (Step model msg)
  , observations: List (Observation model)
  }


scenario : String -> ScenarioPlan model msg -> Scenario model msg
scenario description plan =
  { describing = ""
  , description = formatScenarioDescription description
  , subjectGenerator = plan.subjectGenerator
  , steps = plan.steps
  , observations = plan.observations
  , tags = []
  }


tagged : List String -> Scenario model msg -> Scenario model msg
tagged tags scenarioData =
  { scenarioData | tags = tags }


given : SubjectGenerator model msg -> ScenarioAction model msg
given generator =
  { subjectGenerator = generator
  , steps = []
  }


when : String -> List (Step.Context model -> Step.Command msg) -> ScenarioAction model msg -> ScenarioAction model msg
when condition messageSteps action =
  { action
  | steps =
      messageSteps
        |> List.map (Step.build <| formatCondition condition)
        |> List.append action.steps
  }


observeThat : List (ScenarioAction model msg -> ScenarioPlan model msg) -> ScenarioAction model msg -> ScenarioPlan model msg
observeThat planGenerators action =
  { subjectGenerator = action.subjectGenerator
  , steps = action.steps
  , observations =
      List.foldl (\planGenerator observations ->
        planGenerator action
          |> .observations
          |> List.append observations
      ) [] planGenerators
  }


it : String -> Expectation model -> ScenarioAction model msg -> ScenarioPlan model msg
it description expectation action =
  { subjectGenerator = action.subjectGenerator
  , steps = action.steps
  , observations =
      { description = formatObservationDescription description
      , expectation = expectation
      } :: []
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
