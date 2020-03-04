port module Runner exposing (..)

import Spec.Runner
import Spec.Message exposing (Message)


port elmSpecOut : Message -> Cmd msg
port elmSpecIn : (Message -> msg) -> Sub msg


config : Spec.Runner.Config msg
config =
  { send = elmSpecOut
  , listen = elmSpecIn
  }


program =
  Spec.Runner.browserProgram config
