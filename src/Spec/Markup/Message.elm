module Spec.Markup.Message exposing
  ( runToNextAnimationFrame
  )

import Spec.Message exposing (Message)
import Json.Encode as Encode


runToNextAnimationFrame : Message
runToNextAnimationFrame =
  { home = "_html"
  , name = "nextAnimationFrame"
  , body = Encode.null
  }