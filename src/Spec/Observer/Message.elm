module Spec.Observer.Message exposing
  ( Inquiry
  , inquiry
  , inquiryDecoder
  , observation
  , skipObservation
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
    |> Message.withBody (Message.encode message)


inquiryDecoder : Json.Decoder Inquiry
inquiryDecoder =
  Json.map Inquiry Message.decoder


observation : List String -> String -> Verdict -> Message
observation conditions description verdict =
  Message.for "_observer" "observation"
    |> Message.withBody (
      encodeObservation conditions description verdict
    )


skipObservation : Message
skipObservation =
  Message.for "_observer" "observation"
    |> Message.withBody (
      Encode.object
        [ ("summary", Encode.string "SKIPPED")
        , ("report", Encode.null)
        , ("conditions", Encode.list Encode.string [])
        , ("description", Encode.string "")
        ]
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
      [ ("summary", Encode.string "ACCEPTED")
      , ("report", Encode.null)
      ]
    Reject report ->
      [ ("summary", Encode.string "REJECTED")
      , ("report", Report.encode report)
      ]

