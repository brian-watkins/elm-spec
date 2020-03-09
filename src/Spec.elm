module Spec exposing
  ( Spec
  , Scenario, Script, Plan, Expectation
  , describe
  , scenario
  , tagged
  , given, when, it, observeThat, expect
  )

{-| Functions for writing specs.

A spec is a collection of scenarios, each of which provides an example that
illustrates a behavior belonging to your program. Each scenario follows
the same basic plan:

1. Configure the initial state of the world (and your program).
2. Perform a sequence of steps.
3. Check your xpectations about the new state of the world after the steps have been performed.

Here's a sample spec for a browser program called `App`:

    Spec.describe "some part of my system"
    [ Spec.scenario "the awesome path" (
        Spec.given (
          Spec.Setup.init (App.init testFlags)
            |> Spec.Setup.withView App.view
            |> Spec.Setup.withUpdate App.update
        )
        |> Spec.when "something happens"
          [ Spec.Markup.target << by [ id "some-button" ]
          , Spec.Markup.Event.click
          ]
        |> Spec.it "does the right thing" (
          Spec.Markup.observeElement
            |> Spec.Markup.query << by [ id "some-words" ]
            |> Spec.expect (
              Spec.Claim.isSomethingWhere <|
              Spec.Markup.text <|
              Spec.Claim.isStringContaining "something awesome"
            )
        )
      )
    ]

# Creating a Spec
@docs Spec, Scenario, describe, scenario

# Creating the Scenario Script
@docs Script, given, when

# Turn a Script into a Plan
@docs Plan, Expectation, it, observeThat, expect

# Run Only Certain Scenarios
@docs tagged

-}

import Spec.Setup exposing (Setup)
import Spec.Scenario.Internal as Internal
import Spec.Step as Step
import Spec.Step.Command as Command
import Spec.Observer exposing (Observer)
import Spec.Observer.Internal as Observer
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


{-| Represents what should be the case about some part of the world.

Expectations are checked at the end of the scenario, after all steps of the
script have been performed.
-}
type Expectation model =
  Expectation
    (Internal.Expectation model)


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
    , setup = plan.setup
    , steps = plan.steps
    , observations = plan.observations
    , tags = []
    }


{-| Associate one or more tags with a scenario.

When you run the spec suite with tags specified, only the scenarios
tagged with those tags will be executed.

If you just want to run one or more specific scenarios for debugging or development
purposes, see `Spec.Runner.pick`, which is more convenient to use for those
cases.
-}
tagged : List String -> Scenario model msg -> Scenario model msg
tagged tags (Scenario scenarioData) =
  Scenario
    { scenarioData | tags = tags }


{-| Provide the `Setup` that represents the state of the world at the start of the scenario.

See `Spec.Setup` for functions to construct this representation.
-}
given : Setup model msg -> Script model msg
given provider =
  Script
    { setup = provider
    , steps = []
    }


{-| Specify a description and the steps involved in a scenario.

Each step is a function from `Step.Context` to `Step.Command`, but usually
you will use steps that are provided by other modules, like `Spec.Markup.Event`.

You may provide multiple `when` blocks as part of a scenario.
-}
when : String -> List (Step.Context model -> Step.Command msg) -> Script model msg -> Script model msg
when condition steps (Script script) =
  Script
    { script
    | steps =
        recordConditionStep condition :: steps
          |> List.map Internal.buildStep
          |> List.append script.steps
    }


recordConditionStep : String -> Step.Context model -> Step.Command msg
recordConditionStep condition _ =
  Internal.formatCondition condition
    |> Command.recordCondition


{-| Specify multiple expectations to be checked once the scenario's steps have been performed.
-}
observeThat : List (Script model msg -> Plan model msg) -> Script model msg -> Plan model msg
observeThat planGenerators (Script script) =
  Plan
    { setup = script.setup
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


{-| Specify an expectation to be checked once the scenario's steps have been performed.
-}
it : String -> Expectation model -> Script model msg -> Plan model msg
it description (Expectation expectation) (Script script) =
  Plan
    { setup = script.setup
    , steps = script.steps
    , observations =
        [ Internal.buildObservation description expectation
        ]
    }


{-| Provide an observer with a claim to evaluate.
-}
expect : Claim a -> Observer model a -> Expectation model
expect claim observer =
  Expectation <| Observer.expect claim observer
