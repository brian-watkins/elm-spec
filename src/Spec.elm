module Spec exposing
  ( Spec
  , Scenario, ScenarioPlan, ScenarioAction
  , describe
  , scenario
  , tagged
  , given, when, it, observeThat, expect
  , Model, Msg, Config, Flags
  , program
  , browserProgram
  )

import Spec.Program as Program
import Spec.Message as Message exposing (Message)
import Spec.Subject as Subject exposing (SubjectProvider)
import Spec.Scenario.Internal as Internal
import Spec.Step as Step
import Spec.Observer exposing (Observer, Expectation)
import Spec.Claim exposing (Claim)
import Browser


type alias Spec model msg =
  Internal.Spec model msg


type Scenario model msg =
  Scenario (Internal.Scenario model msg)


type ScenarioAction model msg =
  ScenarioAction (Internal.ScenarioAction model msg)


type ScenarioPlan model msg =
  ScenarioPlan (Internal.ScenarioPlan model msg)


describe : String -> List (Scenario model msg) -> Spec model msg
describe description scenarios =
  scenarios
    |> List.map (\(Scenario scenarioData) -> scenarioData)
    |> List.map (Internal.describing description)
    |> Internal.Spec


scenario : String -> ScenarioPlan model msg -> Scenario model msg
scenario description (ScenarioPlan plan) =
  Scenario
    { specification = ""
    , description = Internal.formatScenarioDescription description
    , subjectProvider = plan.subjectProvider
    , steps = plan.steps
    , observations = plan.observations
    , tags = []
    }


tagged : List String -> Scenario model msg -> Scenario model msg
tagged tags (Scenario scenarioData) =
  Scenario
    { scenarioData | tags = tags }


given : SubjectProvider model msg -> ScenarioAction model msg
given provider =
  ScenarioAction
    { subjectProvider = provider
    , steps = []
    }


when : String -> List (Step.Context model -> Step.Command msg) -> ScenarioAction model msg -> ScenarioAction model msg
when condition messageSteps (ScenarioAction action) =
  ScenarioAction
    { action
    | steps =
        messageSteps
          |> List.map (Internal.buildStep <| Internal.formatCondition condition)
          |> List.append action.steps
    }


observeThat : List (ScenarioAction model msg -> ScenarioPlan model msg) -> ScenarioAction model msg -> ScenarioPlan model msg
observeThat planGenerators (ScenarioAction action) =
  ScenarioPlan
    { subjectProvider = action.subjectProvider
    , steps = action.steps
    , observations =
        List.foldl (\planGenerator observations ->
          let
            (ScenarioPlan plan) = planGenerator (ScenarioAction action)
          in
            plan.observations
              |> List.append observations
        ) [] planGenerators
    }


it : String -> Expectation model -> ScenarioAction model msg -> ScenarioPlan model msg
it description expectation (ScenarioAction action) =
  ScenarioPlan
    { subjectProvider = action.subjectProvider
    , steps = action.steps
    , observations =
        [ Internal.buildObservation description expectation
        ]
    }


expect : Claim a -> Observer model a -> Expectation model
expect claim observer =
  observer claim


---- Program


type alias Config msg =
  { send: Message -> Cmd (Msg msg)
  , outlet: Message -> Cmd msg
  , listen: (Message -> Msg msg) -> Sub (Msg msg)
  }


type alias Flags =
  { tags: List String
  }


type alias Model model msg =
  Program.Model model msg


type alias Msg msg =
  Program.Msg msg


program : Config msg -> List (Spec model msg) -> Program Flags (Model model msg) (Msg msg)
program config specs =
  Platform.worker
    { init = \flags -> Program.init (\_ -> specs) config flags Nothing
    , update = Program.update config
    , subscriptions = Program.subscriptions config
    }


browserProgram : Config msg -> List (Spec model msg) -> Program Flags (Model model msg) (Msg msg)
browserProgram config specs =
  Browser.application
    { init = \flags _ key -> Program.init (\_ -> specs) config flags (Just key)
    , view = Program.view
    , update = Program.update config
    , subscriptions = Program.subscriptions config
    , onUrlRequest = Program.onUrlRequest
    , onUrlChange = Program.onUrlChange
    }
