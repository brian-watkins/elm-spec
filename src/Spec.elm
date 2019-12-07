module Spec exposing
  ( Spec
  , Scenario, Script, Plan
  , describe
  , scenario
  , tagged
  , given, when, it, observeThat, expect
  )

{-| Functions for writing specs.

A spec is a collection of scenarios, each of which provides an example that
illustrates a behavior belonging to your program. Each scenario follows
the same basic plan:

1. Describe the state of the world (and your program) at the beginning of the scenario.
2. Provide a list of steps to perform.
3. List your expectations about the new state of the world after the actions have been completed.

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
@docs Spec, Scenario, describe, scenario

# Creating the Scenario Script
@docs Script, given, when

# Turn a Script into a Plan
@docs Plan, it, observeThat, expect

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


{-| Represents the setup and steps involved in a scenario.
-}
type Script model msg =
  Script (Internal.Script model msg)


{-| Represents the full plan (setup, steps, expectations) involved in a scenario.
-}
type Plan model msg =
  Plan (Internal.Plan model msg)


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
scenario : String -> Plan model msg -> Scenario model msg
scenario description (Plan plan) =
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


{-| Provide a representation of the state of the world at the start of the scenario.

See `Spec.Subject` for functions to construct this representation.
-}
given : SubjectProvider model msg -> Script model msg
given provider =
  Script
    { subjectProvider = provider
    , steps = []
    }


{-| Specify a description and the steps involved in a scenario.

Each step is a function from `Step.Context` to `Step.Command`, but usually
you will use steps that are provided by other modules, like `Spec.Markup.Event`.

You may provide multiple `when` blocks as part of a scenario.
-}
when : String -> List (Step.Context model -> Step.Command msg) -> Script model msg -> Script model msg
when condition messageSteps (Script script) =
  Script
    { script
    | steps =
        messageSteps
          |> List.map (Internal.buildStep <| Internal.formatCondition condition)
          |> List.append script.steps
    }


{-| Specify multiple expectations that should hold once the scenario's steps have been performed.
-}
observeThat : List (Script model msg -> Plan model msg) -> Script model msg -> Plan model msg
observeThat planGenerators (Script script) =
  Plan
    { subjectProvider = script.subjectProvider
    , steps = script.steps
    , observations =
        List.foldl (\planGenerator observations ->
          let
            (Plan plan) = planGenerator (Script script)
          in
            plan.observations
              |> List.append observations
        ) [] planGenerators
    }


{-| Specify an expectation that should hold once the scenario's steps have been performed.
-}
it : String -> Expectation model -> Script model msg -> Plan model msg
it description expectation (Script script) =
  Plan
    { subjectProvider = script.subjectProvider
    , steps = script.steps
    , observations =
        [ Internal.buildObservation description expectation
        ]
    }


{-| Specify an expectation by providing a claim and an observer.
-}
expect : Claim a -> Observer model a -> Expectation model
expect claim observer =
  observer claim
