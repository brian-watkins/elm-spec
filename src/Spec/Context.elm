module Spec.Context exposing
  ( Context
  , expectModel
  )

import Spec.Message exposing (Message)
import Spec.Observer exposing (Observer)


type alias Context model =
  { model: model
  , effects: List Message
  , inquiries: List Message
  }


expectModel : Observer model -> Observer (Context model)
expectModel observer context =
  observer context.model
