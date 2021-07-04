module Spec.Markup.Message exposing
  ( fetchWindow
  )

import Spec.Message as Message exposing (Message)


fetchWindow : Message
fetchWindow =
  Message.for "_html" "query-window"