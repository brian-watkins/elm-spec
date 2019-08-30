port module Runner exposing (..)

import Spec exposing (Spec)
import Spec.Message exposing (Message)
import Main as App


port sendOut : Message -> Cmd msg
port sendIn : (Message -> msg) -> Sub msg


config : Spec.Config msg
config =
  { send = sendOut
  , outlet = sendOut
  , listen = sendIn
  }


program specs =
  Spec.browserProgram config specs