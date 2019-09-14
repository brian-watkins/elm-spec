module Spec.Observation.Message exposing
  ( Inquiry
  , inquiry
  , inquiryDecoder
  , observation
  )

import Spec.Message as Message exposing (Message)
import Spec.Observer exposing (Verdict(..))
import Spec.Observation.Report as Report
import Json.Decode as Json
import Json.Encode as Encode

type alias Inquiry =
  { key: String
  , message: Message
  }


inquiry : String -> Message -> Message
inquiry key message =
  { home = "_observer"
  , name = "inquiry"
  , body = Encode.object
      [ ( "key", Encode.string key )
      , ( "message", Message.encode message )
      ]
  }


inquiryDecoder : Json.Decoder Inquiry
inquiryDecoder =
  Json.map2 Inquiry
    ( Json.field "key" Json.string )
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

