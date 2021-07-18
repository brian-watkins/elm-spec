port module Runner exposing (..)

import Harness exposing (Message)


port elmSpecOut : Message -> Cmd msg
port elmSpecIn : (Message -> msg) -> Sub msg


config : Harness.Config msg
config =
  { send = elmSpecOut
  , listen = elmSpecIn
  }


harness =
  Harness.browserHarness config