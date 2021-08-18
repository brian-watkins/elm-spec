module Harness.Message exposing
  ( harnessActionComplete
  , waitForActionsToComplete
  )

import Spec.Message as Message exposing (Message)


harnessActionComplete : Message
harnessActionComplete =
  Message.for "_harness" "complete"


waitForActionsToComplete : Message
waitForActionsToComplete =
  Message.for "_harness" "wait"