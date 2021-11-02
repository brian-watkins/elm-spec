module Spec exposing
  ( Spec
  , Scenario, Script, Plan, Expectation
  , describe, scenario
  , given, when, it, observeThat, expect
  , Message, Msg, Model, Config, Flags
  , program, browserProgram
  , pick, skip
  )

{-| Functions for writing specs.

A spec is a collection of scenarios, each of which provides an example that
illustrates a behavior belonging to your program. Each scenario follows
the same basic plan:

1. Configure the initial state of the world (and your program).
2. Perform a sequence of steps.
3. Validate your expectations about the new state of the world after the steps have been performed.

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
@docs pick, skip

----

# Create a Spec Suite Program
@docs Config, browserProgram, program

# Spec Suite Program Types
@docs Message, Flags, Msg, Model

-}

import Spec.Setup exposing (Setup)
import Spec.Scenario.Internal as Internal
import Spec.Step as Step
import Spec.Step.Command as Command
import Spec.Observer exposing (Observer)
import Spec.Observer.Internal as Observer
import Spec.Program as Program
import Spec.Message as Message
import Spec.Version as Version
import Spec.Claim exposing (Claim)
import Browser


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
    (Observer.Expectation model)


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


{-| Provide the `Setup` that represents the state of the world at the start of the scenario.

See [Spec.Setup](Spec.Setup) for functions to construct this representation.
-}
given : Setup model msg -> Script model msg
given provider =
  Script
    { setup = provider
    , steps = []
    }


{-| Specify a description and the steps involved in a scenario.

Each step is a function from [Spec.Step.Context](Spec.Step#Context) to [Spec.Step.Command](Spec.Step#Command), but usually
you will use steps that are provided by other modules, like [Spec.Markup.Event](Spec.Markup.Event).

You may provide multiple `when` blocks as part of a scenario.
-}
when : String -> List (Step.Step model msg) -> Script model msg -> Script model msg
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



-- Spec Runner



{-| The spec suite runner must provide a Config, which must be implemented as follows:

Create two ports:

    port elmSpecOut : Message -> Cmd msg
    port elmSpecIn : (Message -> msg) -> Sub msg

And then create a `Config` like so:

    config : Spec.Config msg
    config =
      { send = elmSpecOut
      , listen = elmSpecIn
      }

-}
type alias Config msg =
  { send: Message -> Cmd (Msg msg)
  , listen: (Message -> Msg msg) -> Sub (Msg msg)
  }


{-| Represents a message to pass between elm-spec and the JavaScript elm-spec runner.
-}
type alias Message =
  Message.Message


{-| Flags that the JavaScript runner will pass to the spec suite program.
-}
type alias Flags =
  Program.Flags


{-| Used by the spec suite program.
-}
type alias Model model msg =
  Program.Model model msg


{-| Used by the spec suite program.
-}
type alias Msg msg =
  Program.Msg msg


{-| Create a spec suite program for describing the behavior of headless programs.

Once you've created the `Config` value, I suggest adding a function like so:

    program : List (Spec model msg) -> Program Flags (Model model msg) (Msg msg)
    program =
      Spec.program config

Then, each of your spec modules can implement their own `main` function:

    main =
      Runner.program
        [ ... some specs ...
        ]

The elm-spec runner will find each spec module and run it as its own program.

-}
program : Config msg -> List (Spec model msg) -> Program Flags (Model model msg) (Msg msg)
program config specs =
  Platform.worker
    { init = \flags -> Program.init (\_ -> specs) Version.core config flags Nothing
    , update = Program.update config
    , subscriptions = Program.subscriptions config
    }


{-| Create a spec suite program for describing the behavior of browser-based programs.

Once you've created the `Config` value, I suggest adding a function like so:

    program : List (Spec model msg) -> Program Flags (Model model msg) (Msg msg)
    program =
      Spec.browserProgram config

Then, each of your spec modules can implement their own `main` function:

    main =
      Runner.program
        [ ... some specs ...
        ]

The elm-spec runner will find each spec module and run it as its own program.

-}
browserProgram : Config msg -> List (Spec model msg) -> Program Flags (Model model msg) (Msg msg)
browserProgram config specs =
  Browser.application
    { init = \flags _ key -> Program.init (\_ -> specs) Version.core config flags (Just key)
    , view = Program.view
    , update = Program.update config
    , subscriptions = Program.subscriptions config
    , onUrlRequest = Program.onUrlRequest
    , onUrlChange = Program.onUrlChange
    }


{-| Pick this scenario to be executed when the spec suite runs.

When one or more scenarios are picked, only picked scenarios will be executed.

Note that the first argument to this function must be a port defined like so:

    port elmSpecPick : () -> Cmd msg

I suggest adding a function to the main Runner file in your spec suite, where
you've defined your [Config](Spec#Config) and so on:

    pick =
      Spec.pick elmSpecPick

Then, to pick a scenario to run, do something like this:

    myFunSpec =
      Spec.describe "Some fun stuff"
      [ Runner.pick <| Spec.scenario "fun things happen" (
          ...
        )
      ]

-}
pick : (() -> Cmd msg) -> Scenario model msg -> Scenario model msg
pick _ =
  tagged [ "_elm_spec_pick" ]


{-| Skip this scenario when the spec suite runs.

I suggest adding a function to the main Runner file in your spec suite, where
you've defined your [Config](Spec#Config) and so on:

    skip =
      Spec.skip

Then, to skip a scenario, do something like this:

    myFunSpec =
      Spec.describe "Some fun stuff"
      [ Runner.skip <| Spec.scenario "fun things happen" (
          ...
        )
      ]

-}
skip : Scenario model msg -> Scenario model msg
skip =
  tagged [ "_elm_spec_skip" ]


tagged : List String -> Scenario model msg -> Scenario model msg
tagged tags (Scenario scenarioData) =
  Scenario
    { scenarioData | tags = tags }
