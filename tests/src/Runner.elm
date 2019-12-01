port module Runner exposing
  ( program
  , browserProgram
  , runSuiteWithVersion
  , config
  )

import Spec exposing (Spec)
import Spec.Program
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


initForTests : Spec.Config msg -> (String -> Maybe (Spec model msg)) -> Flags -> Maybe Key -> (Spec.Model model msg, Cmd (Spec.Msg msg))
initForTests specConfig specLocator flags maybeKey =
  Spec.Program.init (\_ ->
    case specLocator flags.specName of
      Just spec ->
        [ spec ]
      Nothing ->
        Debug.todo <| "Unknown spec: " ++ flags.specName
  ) 1 specConfig { version = 1, tags = [] } maybeKey


program : (String -> Maybe (Spec model msg)) -> Program Flags (Spec.Model model msg) (Spec.Msg msg)
program specLocator =
  Platform.worker
    { init = \flags -> initForTests config specLocator flags Nothing
    , update = Spec.Program.update config
    , subscriptions = Spec.Program.subscriptions config
    }


browserProgram : (String -> Maybe (Spec model msg)) -> Program Flags (Spec.Model model msg) (Spec.Msg msg)
browserProgram specLocator =
  Browser.application
    { init = \flags _ key -> initForTests config specLocator flags (Just key)
    , view = Spec.Program.view
    , update = Spec.Program.update config
    , subscriptions = Spec.Program.subscriptions config
    , onUrlRequest = Spec.Program.onUrlRequest
    , onUrlChange = Spec.Program.onUrlChange
    }


runSuiteWithVersion : Int -> List (Spec model msg) -> Program Spec.Flags (Spec.Model model msg) (Spec.Msg msg)
runSuiteWithVersion elmSpecVersion specs =
  Browser.application
    { init = \flags _ key ->
        Spec.Program.init
          (\_ -> specs)
          elmSpecVersion
          config
          flags
          (Just key)
    , view = Spec.Program.view
    , update = Spec.Program.update config
    , subscriptions = Spec.Program.subscriptions config
    , onUrlRequest = Spec.Program.onUrlRequest
    , onUrlChange = Spec.Program.onUrlChange
    }