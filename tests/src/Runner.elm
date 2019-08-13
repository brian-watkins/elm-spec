port module Runner exposing
  ( program
  , config
  )

import Spec exposing (Spec)
import Spec.Message exposing (Message)
import Task


port sendOut : Message -> Cmd msg
port sendIn : (Message -> msg) -> Sub msg


config : Spec.Config msg
config =
  { send = sendOut
  , outlet = sendOut
  , listen = sendIn
  }


type alias Flags =
  { specName: String
  }


init : (String -> Spec model msg) -> Flags -> (Spec.Model model msg, Cmd (Spec.Msg msg) )
init specLocator flags =
  Spec.init [ specLocator flags.specName ] ()


program : (String -> Spec model msg) -> Program Flags (Spec.Model model msg) (Spec.Msg msg)
program specLocator =
  Platform.worker
    { init = init specLocator
    , update = Spec.update config
    , subscriptions = Spec.subscriptions config
    }