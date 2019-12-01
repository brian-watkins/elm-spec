module Spec.Observation.Message exposing
  ( Inquiry
  , inquiry
  , inquiryDecoder
  , observation
  , isObservationMessage
  )

import Spec.Message as Message exposing (Message)
import Spec.Message.Internal as Message
import Spec.Claim exposing (Verdict(..))
import Spec.Report as Report
import Json.Decode as Json
import Json.Encode as Encode


type alias Inquiry =
  { message: Message
  }


isObservationMessage : Message -> Bool
isObservationMessage =
  Message.belongsTo "_observer"


inquiry : Message -> Message
inquiry message =
  Message.for "_observer" "inquiry"
    |> Message.withBody (
      Encode.object
        [ ( "message", Message.encode message )
        ]
    )


inquiryDecoder : Json.Decoder Inquiry
inquiryDecoder =
  Json.map Inquiry
    ( Json.field "message" Message.decoder )


observation : List String -> String -> Verdict -> Message
observation conditions description verdict =
  Message.for "_observer" "observation"
    |> Message.withBody (
      encodeObservation conditions description verdict
    )


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

