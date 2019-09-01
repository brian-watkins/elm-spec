module Procedure.Extra exposing
  ( bump
  )

import Procedure exposing (Procedure)
import Task
import Process


bump : a -> Procedure e a msg
bump msg =
  Process.sleep 0
    |> Task.andThen (\_ -> Task.succeed msg)
    |> Procedure.fromTask
