module Spec.Scenario.Internal exposing
  ( Step
  , buildStep
  )

import Spec.Step exposing (Context, Command)


type alias Step model msg =
  { run: Context model -> Command msg
  , condition: String
  }


buildStep : String -> (Context model -> Command msg) -> Step model msg
buildStep description stepper =
  { run = stepper
  , condition = description
  }
