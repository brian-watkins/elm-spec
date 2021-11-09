module Spec.Setup.Message exposing
  ( configCommandMessage
  , configRequestMessage
  )

import Spec.Message as Message exposing (Message)
import Spec.Message.Internal as Message
import Json.Encode as Encode


configCommandMessage : Message -> Message
configCommandMessage =
  configMessage "command"


configRequestMessage : Message -> Message
configRequestMessage =
  configMessage "request"


configMessage : String -> Message -> Message
configMessage configType message =
  Message.for "_scenario" "configure"
    |> Message.withBody (
      Encode.object
        [ ("message", Message.encode message)
        , ("type", Encode.string configType)
        ]
    )