module CompilationError.BadHarness exposing (..)

import Harness exposing (Expectation, setup)
import Spec.Setup as Setup exposing (Setup)
import Runner

-- Setup

defaultSetup =
  Setup.initWithModel { value = 88 }


setups =
  [ Harness.export "default" <| setupssss defaultSetup
  ]


main =
  Runner.harness setups