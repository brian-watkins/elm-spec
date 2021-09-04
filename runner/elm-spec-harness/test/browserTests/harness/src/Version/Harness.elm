module Version.Harness exposing (..)

import Runner
import Dict

main =
  Runner.harnessWithVersion 0
    { setups = Dict.empty
    , steps = Dict.empty
    , expectations = Dict.empty
    }