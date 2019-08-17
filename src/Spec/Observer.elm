module Spec.Observer exposing
  ( Observer
  , Msg(..)
  , Verdict(..)
  , accept
  , reject
  , isEqual
  , inquiryDecoder
  , Inquiry
  , inquiry
  , observation
  , mapRejection
  )

import Spec.Message as Message exposing (Message)
import Json.Encode as Encode
import Json.Decode as Json


type Msg
  = Inquire Message
  | Render Verdict


type alias Observer a =
  a -> Msg


type alias Inquiry =
  { key: String
  , message: Message
  }


type Verdict
  = Accept
  | Reject String


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


mapRejection : (String -> String) -> Msg -> Msg
mapRejection mapper msg =
  case msg of
    Render (Reject reason) ->
      Render << Reject <| mapper reason
    _ ->
      msg


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
      , ("message", Encode.null)
      ]
    Reject reason ->
      [ ("summary", Encode.string "REJECT")
      , ("message", Encode.string reason)
      ]


accept : Msg
accept =
  Render Accept


reject : String -> Msg
reject =
  Render << Reject


isEqual : a -> Observer a
isEqual expected actual =
  if expected == actual then
    accept
  else
    reject <| "Expected " ++ (toString expected) ++ " to equal " ++ (toString actual) ++ ", but it does not."
      

toString : a -> String
toString =
  Elm.Kernel.Debug.toString