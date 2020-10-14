module Spec.Markup.Message exposing
  ( runToNextAnimationFrame
  , fetchWindow
  )

import Spec.Message as Message exposing (Message)
import Json.Encode as Encode


runToNextAnimationFrame : Message
runToNextAnimationFrame =
  Message.for "_step" "nextAnimationFrame"


fetchWindow : Message
fetchWindow =
  Message.for "_html" "query-window"