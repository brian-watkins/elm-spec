module Spec exposing
  ( Spec
  , Scenario, ScenarioPlan, ScenarioAction
  , describe
  , scenario
  , tagged
  , given, when, it, observeThat, expect
  )

{-| Functions for writing specs.

Here's a sample spec for a browser program called `App`:

    Spec.describe "some part of my system"
    [ Spec.scenario "the awesome path" (
        Spec.given (
          Spec.Subject.init (App.init testFlags)
            |> Spec.Subject.withView App.view
            |> Spec.Subject.withUpdate App.update
        )
        |> Spec.when "something happens"
          [ Spec.Markup.target << by [ id "some-button" ]
          , Spec.Markup.Event.click
          ]
        |> Spec.it "does the right thing" (
          Spec.Markup.observeElement
            |> Spec.Markup.query << by [ id "some-words" ]
            |> Spec.expect (Spec.Markup.hasText "something awesome")
        )
      )
    ]

# Creating a Spec
@docs Spec, describe

# Creating a Scenario
@docs Scenario, ScenarioPlan, ScenarioAction, scenario, given, when, it, observeThat, expect

# Tag a Scenario
@docs tagged

-}

import Spec.Subject as Subject exposing (SubjectProvider)
import Spec.Scenario.Internal as Internal
import Spec.Step as Step
import Spec.Observer exposing (Observer, Expectation)
import Spec.Claim exposing (Claim)


{-| Represents the spec.
-}
type alias Spec model msg =
  Internal.Spec model msg


{-| Represents a particular scenario in a spec.
-}
type Scenario model msg =
  Scenario (Internal.Scenario model msg)


{-| Represents the setup and actions involved in a scenario.
-}
type ScenarioAction model msg =
  ScenarioAction (Internal.ScenarioAction model msg)


{-| Represents the full plan (setup, actions, expectations) involved in a scenario.
-}
type ScenarioPlan model msg =
  ScenarioPlan (Internal.ScenarioPlan model msg)


{-| Specify a description and a list of scenarios that compose the spec.
-}
describe : String -> List (Scenario model msg) -> Spec model msg
describe description scenarios =
  scenarios
    |> List.map (\(Scenario scenarioData) -> scenarioData)
    |> List.map (Internal.describing description)
    |> Internal.Spec


{-| Create a scenario with a description and a plan.
-}
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


{-| Associate one or more tags with a scenario.

When you run the spec suite with specific tags specified, only the scenarios
tagged with those tags will be executed.
-}
tagged : List String -> Scenario model msg -> Scenario model msg
tagged tags (Scenario scenarioData) =
  Scenario
    { scenarioData | tags = tags }


{-| Provide the subject whose behavior you will describe.
-}
given : SubjectProvider model msg -> ScenarioAction model msg
given provider =
  ScenarioAction
    { subjectProvider = provider
    , steps = []
    }


{-| Specify a description and a list of steps for some action involved in a scenario.

You may specify multiple `when` blocks as part of a scenario.
-}
when : String -> List (Step.Context model -> Step.Command msg) -> ScenarioAction model msg -> ScenarioAction model msg
when condition messageSteps (ScenarioAction action) =
  ScenarioAction
    { action
    | steps =
        messageSteps
          |> List.map (Internal.buildStep <| Internal.formatCondition condition)
          |> List.append action.steps
    }


{-| Specify multiple expectations that should hold once the scenario's actions have been executed.
-}
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


{-| Specify an expectation that should hold once the scenario's actions have been executed.
-}
it : String -> Expectation model -> ScenarioAction model msg -> ScenarioPlan model msg
it description expectation (ScenarioAction action) =
  ScenarioPlan
    { subjectProvider = action.subjectProvider
    , steps = action.steps
    , observations =
        [ Internal.buildObservation description expectation
        ]
    }


{-| Specify an expectation by providing a claim and an observer.
-}
expect : Claim a -> Observer model a -> Expectation model
expect claim observer =
  observer claim
