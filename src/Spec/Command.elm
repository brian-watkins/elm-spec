module Spec.Command exposing
  ( send
  , fake
  )

{-| Functions to work with `Cmd` values in a spec.

@docs send, fake
-}

import Spec.Step as Step
import Spec.Step.Command as Command
import Spec.Message as Message exposing (Message)
import Task
import Json.Encode as Encode


{-| A step that sends a command.
-}
send : Cmd msg -> Step.Step model msg
send cmd =
  \_ ->
    Command.sendToProgram cmd


{-| Generate a `Cmd` value that will send a `Msg` to the `update`
function provided in the setup of the scenario.
-}
fake : msg -> Cmd msg
fake msg =
  Task.succeed never
    |> Task.perform (always msg)