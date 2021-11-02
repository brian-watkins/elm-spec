port module Runner exposing (..)

import Harness exposing (Harness, Message)
import Harness.Program as Program
import Browser


port elmSpecOut : Message -> Cmd msg
port elmSpecIn : (Message -> msg) -> Sub msg


config : Harness.Config msg
config =
  { send = elmSpecOut
  , listen = elmSpecIn
  }


harness =
  Harness.browserHarness config


harnessWithVersion : Int -> Harness model msg -> Platform.Program Program.Flags (Program.Model model msg) (Program.Msg msg)
harnessWithVersion expectedVersion harnessConfig =
  Browser.application
    { init = \flags _ key ->
        Program.init expectedVersion flags (Just key)
    , view = Program.view
    , update = Program.update config harnessConfig
    , subscriptions = Program.subscriptions config
    , onUrlRequest = Program.onUrlRequest
    , onUrlChange = Program.onUrlChange
    }