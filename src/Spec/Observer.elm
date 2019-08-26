module Spec.Observer exposing
  ( Observer
  , Verdict(..)
  , inquiry
  , observation
  , isEqual
  , inquiryDecoder
  )

import Spec.Message as Message exposing (Message)
import Spec.Observer.Report as Report exposing (Report)
import Json.Encode as Encode
import Json.Decode as Json


type alias Observer a =
  a -> Verdict


type alias Inquiry =
  { key: String
  , message: Message
  }


type Verdict
  = Accept
  | Reject Report


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


isEqual : a -> Observer a
isEqual expected actual =
  if expected == actual then
    Accept
  else
    Reject <| Report.batch
      [ Report.fact "Expected" <| toString expected
      , Report.fact "to equal" <| toString actual
      ]
      

toString : a -> String
toString =
  Elm.Kernel.Debug.toString