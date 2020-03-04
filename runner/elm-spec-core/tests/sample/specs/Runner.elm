port module Runner exposing (..)

import Spec.Runner exposing (Message)


port elmSpecOut : Message -> Cmd msg
port elmSpecIn : (Message -> msg) -> Sub msg
port elmSpecPick : () -> Cmd msg


config : Spec.Runner.Config msg
config =
  { send = elmSpecOut
  , listen = elmSpecIn
  }


pick =
  Spec.Runner.pick elmSpecPick


program =
  Spec.Runner.browserProgram config


workerProgram =
  Spec.Runner.program config