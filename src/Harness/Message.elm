module Harness.Message exposing
  ( harnessActionComplete
  , prepareHarnessForAction
  )

import Spec.Message as Message exposing (Message)


harnessActionComplete : Message
harnessActionComplete =
  Message.for "_harness" "complete"


prepareHarnessForAction : Message
prepareHarnessForAction =
  Message.for "_harness" "prepare"