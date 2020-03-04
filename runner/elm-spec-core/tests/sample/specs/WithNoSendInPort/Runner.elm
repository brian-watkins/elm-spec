port module WithNoSendInPort.Runner exposing (..)

import Spec exposing (Spec)
import Spec.Runner
import Spec.Message exposing (Message)


port elmSpecOut : Message -> Cmd msg
port somethingOtherThanSendIn : (Message -> msg) -> Sub msg


config : Spec.Runner.Config msg
config =
  { send = elmSpecOut
  , listen = somethingOtherThanSendIn
  }


program =
  Spec.Runner.browserProgram config


workerProgram =
  Spec.Runner.program config