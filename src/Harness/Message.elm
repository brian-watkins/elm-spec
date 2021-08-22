module Harness.Message exposing
  ( harnessActionComplete
  , abortHarness
  )

import Spec.Message as Message exposing (Message)
import Spec.Report as Report exposing (Report)


harnessActionComplete : Message
harnessActionComplete =
  Message.for "_harness" "complete"


abortHarness : Report -> Message
abortHarness report =
  Message.for "_harness" "abort"
    |> Message.withBody (Report.encode report)