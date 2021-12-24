module Spec.Step exposing
  ( Step
  , Context
  , Command
  , model
  , halt
  , log
  )

{-| A scenario script is a sequence of steps. A step is a function from a `Context`,
which represents the current scenario state, to a `Command`, which describes an action to be
executed before moving to the next step.

See `Spec.Command`, `Spec.File`, `Spec.Navigator`, `Spec.Http`, `Spec.Markup`,
`Spec.Markup.Event`, `Spec.Port`, and `Spec.Time` for steps you can use to build a scenario script.

@docs Step, Context, Command

# Using the Context
@docs model

# Basic Commands
@docs halt, log

-}

import Spec.Step.Command as Command
import Spec.Step.Context as Context
import Spec.Report exposing (Report)


{-| Represents a step in a scenario script.
-}
type alias Step model msg =
  Context.Context model -> Command.Command msg


{-| Represents the current state of the program.
-}
type alias Context model =
  Context.Context model


{-| Represents an action to be performed.
-}
type alias Command msg =
  Command.Command msg


{-| Get the current program model from the `Context`.
-}
model : Context model -> model
model =
  Context.model


{-| The spec runner will halt the scenario and print the given report.
-}
halt : Report -> Command msg
halt =
  Command.halt


{-| The spec runner will log the given report to the console.
-}
log : Report -> Command msg
log =
  Command.log