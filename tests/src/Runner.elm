port module Runner exposing
  ( program
  )

import Spec exposing (Spec)
import Spec.Message exposing (Message)
import Task


port sendOut : Message -> Cmd msg


type Msg msg
  = SpecMsg (Spec.Msg msg)


type alias Model model msg =
  { specModel: Spec.Model model msg
  }


testConfig : Spec.Config (Spec.Msg msg)
testConfig =
  { out = sendOut
  }


sendSpecMessage : Message -> Cmd (Spec.Msg msg)
sendSpecMessage message =
  Task.succeed message
    |> Task.perform Spec.messageTagger


update : Msg msg -> Model model msg -> (Model model msg, Cmd (Msg msg))
update msg model =
  case msg of
    SpecMsg specMsg ->
      Spec.update testConfig specMsg model.specModel
        |> Tuple.mapFirst (\updated -> { model | specModel = updated })
        |> Tuple.mapSecond (Cmd.map SpecMsg)


subscriptions : Model model msg -> Sub (Msg msg)
subscriptions model =
  Spec.subscriptions model.specModel
    |> Sub.map SpecMsg


type alias Flags =
  { specName: String
  }


init : (String -> Spec model msg) -> Flags -> ( Model model msg, Cmd (Msg msg) )
init specLocator flags =
  Spec.init (specLocator flags.specName) ()
    |> Tuple.mapFirst (\model -> { specModel = model })
    |> Tuple.mapSecond (\_ -> sendSpecMessage Spec.Message.startSpec)
    |> Tuple.mapSecond (Cmd.map SpecMsg)


program : (String -> Spec model msg) -> Program Flags (Model model msg) (Msg msg)
program specLocator =
  Platform.worker
    { init = init specLocator
    , update = update
    , subscriptions = subscriptions
    }