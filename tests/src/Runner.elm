port module Runner exposing
  ( program
  , browserProgram
  , config
  )

import Spec exposing (Spec)
import Spec.Message exposing (Message)
import Task
import Browser exposing (UrlRequest)
import Browser.Navigation exposing (Key)
import Url exposing (Url)
import Html


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


init : Spec.Config msg -> (String -> Maybe (Spec model msg)) -> Flags -> (Spec.Model model msg, Cmd (Spec.Msg msg) )
init specConfig specLocator flags =
  case specLocator flags.specName of
    Just spec ->
      Spec.init specConfig [ spec ] ()
    Nothing ->
      Elm.Kernel.Debug.todo <| "Unknown spec: " ++ flags.specName


program : (String -> Maybe (Spec model msg)) -> Program Flags (Spec.Model model msg) (Spec.Msg msg)
program specLocator =
  Platform.worker
    { init = init config specLocator
    , update = Spec.update config
    , subscriptions = Spec.subscriptions config
    }
  

initBrowserProgram : Spec.Config msg -> (String -> Maybe (Spec model msg)) -> Flags -> Url -> Key -> (Spec.Model model msg, Cmd (Spec.Msg msg) )
initBrowserProgram specConfig specLocator flags url key =
  case specLocator flags.specName of
    Just spec ->
      Spec.initBrowserProgram specConfig [ spec ] { tags = [] } url key
    Nothing ->
      Elm.Kernel.Debug.todo <| "Unknown spec: " ++ flags.specName


browserProgram : (String -> Maybe (Spec model msg)) -> Program Flags (Spec.Model model msg) (Spec.Msg msg)
browserProgram specLocator =
  Browser.application
    { init = initBrowserProgram config specLocator
    , view = Spec.view
    , update = Spec.update config
    , subscriptions = Spec.subscriptions config
    , onUrlRequest = Spec.onUrlRequest
    , onUrlChange = Spec.onUrlChange
    }