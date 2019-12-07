module Spec.Runner exposing
  ( Msg
  , Model
  , Config
  , Flags
  , program
  , browserProgram
  )

import Spec exposing (Spec)
import Spec.Program as Program
import Spec.Message as Message exposing (Message)
import Browser


elmSpecVersion = 1


type alias Config msg =
  { send: Message -> Cmd (Msg msg)
  , outlet: Message -> Cmd msg
  , listen: (Message -> Msg msg) -> Sub (Msg msg)
  }


type alias Flags =
  { tags: List String
  , version: Int
  }


type alias Model model msg =
  Program.Model model msg


type alias Msg msg =
  Program.Msg msg


program : Config msg -> List (Spec model msg) -> Program Flags (Model model msg) (Msg msg)
program config specs =
  Platform.worker
    { init = \flags -> Program.init (\_ -> specs) elmSpecVersion config flags Nothing
    , update = Program.update config
    , subscriptions = Program.subscriptions config
    }


browserProgram : Config msg -> List (Spec model msg) -> Program Flags (Model model msg) (Msg msg)
browserProgram config specs =
  Browser.application
    { init = \flags _ key -> Program.init (\_ -> specs) elmSpecVersion config flags (Just key)
    , view = Program.view
    , update = Program.update config
    , subscriptions = Program.subscriptions config
    , onUrlRequest = Program.onUrlRequest
    , onUrlChange = Program.onUrlChange
    }
