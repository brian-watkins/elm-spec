port module WithNoSendInPort.Runner exposing (..)

import Spec exposing (Spec)
import Spec.Message exposing (Message)


port elmSpecOut : Message -> Cmd msg
port somethingOtherThanSendIn : (Message -> msg) -> Sub msg


config : Spec.Config msg
config =
  { send = elmSpecOut
  , listen = somethingOtherThanSendIn
  }


program =
  Spec.browserProgram config


workerProgram =
  Spec.program config