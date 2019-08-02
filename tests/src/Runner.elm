port module Runner exposing
  ( program
  )

import Spec exposing (Spec)
import Spec.Message exposing (Message)
import Task


port sendOut : Message -> Cmd msg
port sendIn : (Message -> msg) -> Sub msg


testConfig : Spec.Config (Spec.Msg msg)
testConfig =
  { out = sendOut
  }


sendSpecMessage : Message -> Cmd (Spec.Msg msg)
sendSpecMessage message =
  Task.succeed message
    |> Task.perform Spec.messageTagger


subscriptions : Spec.Model model msg -> Sub (Spec.Msg msg)
subscriptions model =
  Sub.batch
  [ Spec.subscriptions model
  , sendIn Spec.messageTagger
  ]


type alias Flags =
  { specName: String
  }


init : (String -> Spec model msg) -> Flags -> (Spec.Model model msg, Cmd (Spec.Msg msg) )
init specLocator flags =
  Spec.init (specLocator flags.specName) ()
    |> Tuple.mapSecond (\_ -> sendSpecMessage Spec.Message.startSpec)


program : (String -> Spec model msg) -> Program Flags (Spec.Model model msg) (Spec.Msg msg)
program specLocator =
  Platform.worker
    { init = init specLocator
    , update = Spec.update testConfig
    , subscriptions = subscriptions
    }