module Spec.Step.Command exposing
  ( Command(..)
  , map
  , withDefault
  , toCmdOr
  )

import Spec.Message exposing (Message)


type Command msg
  = SendMessage Message
  | SendCommand (Cmd msg)
  | DoNothing


map : (msg -> a) -> Command msg -> Command a
map mapper stepCommand =
  case stepCommand of
    SendMessage message ->
      SendMessage message
    SendCommand command ->
      SendCommand <| Cmd.map mapper command
    DoNothing ->
      DoNothing


withDefault : Cmd msg -> Command msg -> Command msg
withDefault default stepCommand =
  case stepCommand of
    SendMessage message ->
      SendMessage message
    SendCommand command ->
      SendCommand command
    DoNothing ->
      SendCommand default


toCmdOr : (Message -> Cmd msg) -> Command msg -> Cmd msg
toCmdOr sender stepCommand =
  case stepCommand of
    SendMessage message ->
      sender message
    SendCommand command ->
      command
    DoNothing ->
      Cmd.none

