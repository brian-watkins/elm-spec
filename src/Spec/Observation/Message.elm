module Spec.Observation.Message exposing
  ( Inquiry
  , inquiry
  , inquiryDecoder
  , observation
  , isObservationMessage
  )

import Spec.Message as Message exposing (Message)
import Spec.Observer exposing (Verdict(..))
import Spec.Observation.Report as Report
import Json.Decode as Json
import Json.Encode as Encode


type alias Inquiry =
  { message: Message
  }


isObservationMessage : Message -> Bool
isObservationMessage message =
  message.home == "_observer"


inquiry : Message -> Message
inquiry message =
  { home = "_observer"
  , name = "inquiry"
  , body = Encode.object
      [ ( "message", Message.encode message )
      ]
  }


inquiryDecoder : Json.Decoder Inquiry
inquiryDecoder =
  Json.map Inquiry
    ( Json.field "message" Message.decoder )


observation : List String -> String -> Verdict -> Message
observation conditions description verdict =
  { home = "_observer"
  , name = "observation"
  , body = encodeObservation conditions description verdict
  }


encodeObservation : List String -> String -> Verdict -> Encode.Value
encodeObservation conditions description verdict =
  verdictAttributes verdict
    |> List.append
      [ ("conditions", Encode.list Encode.string conditions)
      , ("description", Encode.string description)
      ]
    |> Encode.object


verdictAttributes verdict =
  case verdict of
    Accept ->
      [ ("summary", Encode.string "ACCEPT")
      , ("report", Encode.null)
      ]
    Reject report ->
      [ ("summary", Encode.string "REJECT")
      , ("report", Report.encoder report)
      ]

