module Spec.Scenario.State exposing
  ( Msg(..)
  , Command(..)
  , updateWith
  )

import Spec.Message exposing (Message)
import Spec.Report exposing (Report)
import Browser exposing (UrlRequest)
import Url exposing (Url)
import Task


type Msg msg
  = ReceivedMessage Message
  | ProgramMsg msg
  | Continue
  | Abort Report
  | OnUrlRequest UrlRequest
  | OnUrlChange Url


type Command msg
  = Do (Cmd msg)
  | DoAndRender (Cmd msg)
  | Send Message
  | SendMany (List Message)
  | Transition


updateWith : (Msg msg) -> Command (Msg msg)
updateWith msg =
  Task.succeed never
    |> Task.perform (always msg)
    |> Do