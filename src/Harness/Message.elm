module Harness.Message exposing
  ( harnessActionComplete
  )

import Spec.Message as Message exposing (Message)


harnessActionComplete : Message
harnessActionComplete =
  Message.for "_harness" "complete"