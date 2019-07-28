module Spec.Message exposing
  ( Message
  , observation
  , startSpec
  , stepComplete
  )

import Observer exposing (Verdict(..))
import Json.Encode as Encode exposing (Value)


type alias Message =
  { home: String
  , body: Value
  }


startSpec : Message
startSpec =
  { home = "spec"
  , body = Encode.string "START"
  }


stepComplete : Message
stepComplete =
  { home = "spec"
  , body = Encode.string "STEP_COMPLETE"
  }


observation : Verdict -> Message
observation verdict =
  case verdict of
    Accept ->
      { home = "spec-observation"
      , body = Encode.object [ ("summary", Encode.string "ACCEPT"), ("message", Encode.null) ]
      }
    Reject message ->
      { home = "spec-observation"
      , body = Encode.object [ ("summary", Encode.string "REJECT"), ("message", Encode.string message) ]
      }
