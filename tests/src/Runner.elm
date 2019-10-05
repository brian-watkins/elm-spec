port module Runner exposing
  ( program
  , browserProgram
  , browserApplication
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
      Debug.todo <| "Unknown spec: " ++ flags.specName


program : (String -> Maybe (Spec model msg)) -> Program Flags (Spec.Model model msg) (Spec.Msg msg)
program specLocator =
  Platform.worker
    { init = init config specLocator
    , update = Spec.update config
    , subscriptions = Spec.subscriptions config
    }
  

browserProgram : (String -> Maybe (Spec model msg)) -> Program Flags (Spec.Model model msg) (Spec.Msg msg)
browserProgram specLocator =
  Browser.element
    { init = init config specLocator
    , update = Spec.update config
    , view = Spec.view
    , subscriptions = Spec.subscriptions config
    }


initApplication : Spec.Config msg -> (String -> Maybe (Spec model msg)) -> Flags -> Url -> Key -> (Spec.Model model msg, Cmd (Spec.Msg msg) )
initApplication specConfig specLocator flags url key =
  case specLocator flags.specName of
    Just spec ->
      Spec.initApplication specConfig [ spec ] () url key
    Nothing ->
      Debug.todo <| "Unknown spec: " ++ flags.specName


browserApplication : (String -> Maybe (Spec model msg)) -> Program Flags (Spec.Model model msg) (Spec.Msg msg)
browserApplication specLocator =
  Browser.application
    { init = initApplication config specLocator
    , view = \model -> { title = "elm-spec", body = [ Spec.view model ] }
    , update = Spec.update config
    , subscriptions = Spec.subscriptions config
    , onUrlRequest = Spec.onUrlRequest
    , onUrlChange = Spec.onUrlChange
    }