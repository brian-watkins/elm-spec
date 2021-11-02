module Version.Harness exposing (..)

import Runner
import Dict

main =
  Runner.harnessWithVersion 0
    { initialStates = []
    , scripts = []
    , expectations = []
    }