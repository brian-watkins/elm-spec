port module Runner exposing (..)

import Spec exposing (Spec)
import Spec.Message exposing (Message)


port elmSpecOut : Message -> Cmd msg
port elmSpecIn : (Message -> msg) -> Sub msg


config : Spec.Config msg
config =
  { send = elmSpecOut
  , outlet = elmSpecOut
  , listen = elmSpecIn
  }


program specs =
  Spec.browserProgram config specs


workerProgram specs =
  Spec.program config specs