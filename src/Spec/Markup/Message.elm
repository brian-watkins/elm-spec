module Spec.Markup.Message exposing
  ( runToNextAnimationFrame
  )

import Spec.Message as Message exposing (Message)
import Json.Encode as Encode


runToNextAnimationFrame : Message
runToNextAnimationFrame =
  Message.for "_html" "nextAnimationFrame"