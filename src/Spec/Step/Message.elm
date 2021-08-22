module Spec.Step.Message exposing
  ( stepMessage
  , stepComplete
  , stepRequest
  , runToNextAnimationFrame
  )

import Spec.Message as Message exposing (Message)
import Spec.Message.Internal as Message
import Json.Encode as Encode


stepMessage : Message -> Message
stepMessage message =
  Message.for "_scenario" "step"
    |> Message.withBody (
      Encode.object
        [ ("message", Message.encode message)
        ]
    )


stepComplete : Message
stepComplete =
  Message.for "_step" "complete"


runToNextAnimationFrame : Message
runToNextAnimationFrame =
  Message.for "_step" "nextAnimationFrame"


stepRequest : Message -> Message
stepRequest message =
  Message.for "_step" "request"
    |> Message.withBody (Message.encode message)
