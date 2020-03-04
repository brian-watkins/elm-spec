port module WithNoSendOutPort.Runner exposing (..)

import Spec exposing (Spec)
import Spec.Runner
import Spec.Message exposing (Message)


port somerthingOtherThanSendOut : Message -> Cmd msg
port elmSpecIn : (Message -> msg) -> Sub msg


config : Spec.Runner.Config msg
config =
  { send = somerthingOtherThanSendOut
  , listen = elmSpecIn
  }


program =
  Spec.Runner.browserProgram config


workerProgram =
  Spec.Runner.program config