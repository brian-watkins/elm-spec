port module WithNoSendOutPort.Runner exposing (..)

import Spec exposing (Spec)
import Spec.Message exposing (Message)


port somerthingOtherThanSendOut : Message -> Cmd msg
port elmSpecIn : (Message -> msg) -> Sub msg


config : Spec.Config msg
config =
  { send = somerthingOtherThanSendOut
  , listen = elmSpecIn
  }


program =
  Spec.browserProgram config


workerProgram =
  Spec.program config