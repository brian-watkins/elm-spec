module Spec.Binary exposing
  ( jsonDecoder
  , jsonEncode
  , decodeToString
  , encodeString
  )

import Bytes exposing (Bytes)
import Bytes.Decode as Decode
import Bytes.Encode as Encode
import Json.Decode as Json
import Json.Encode as JsonEncode


jsonDecoder : Json.Decoder Bytes
jsonDecoder =
  Json.list Json.int
    |> Json.map (toBytes Encode.unsignedInt8)


jsonEncode : Bytes -> Json.Value
jsonEncode binaryContent =
  JsonEncode.list JsonEncode.int <| toList Decode.unsignedInt8 binaryContent


decodeToString : Bytes -> Maybe String
decodeToString binaryContent =
  Decode.decode (Decode.string <| Bytes.width binaryContent) binaryContent


encodeString : String -> Bytes
encodeString =
  Encode.encode << Encode.string


toBytes : (a -> Encode.Encoder) -> List a -> Bytes
toBytes encoder ints =
  Encode.encode (Encode.sequence <| List.map encoder ints)


toList : Decode.Decoder a -> Bytes -> List a
toList binaryDecoder binaryContent =
  Decode.decode (listDecoder (Bytes.width binaryContent) binaryDecoder) binaryContent
    |> Maybe.withDefault []
    |> List.reverse


listDecoder : Int -> Decode.Decoder a -> Decode.Decoder (List a)
listDecoder width binaryDecoder =
  Decode.loop (width, []) (listStep binaryDecoder)


listStep : Decode.Decoder a -> (Int, List a) -> Decode.Decoder (Decode.Step (Int, List a) (List a))
listStep binaryDecoder (remaining, items) =
  if remaining == 0 then
    Decode.succeed (Decode.Done items)
  else
    Decode.map (\next -> Decode.Loop (remaining - 1, next :: items)) binaryDecoder
