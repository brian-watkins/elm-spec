module Spec.Command exposing
  ( send
  , fake
  )

import Spec.Step as Step
import Task
import Json.Encode as Encode


send : Cmd msg -> Step.Context model -> Step.Command msg
send cmd _ =
  Step.sendCommand cmd


fake : msg -> Cmd msg
fake msg =
  Task.succeed never
    |> Task.perform (always msg)