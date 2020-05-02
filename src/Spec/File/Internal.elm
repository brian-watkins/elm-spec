module Spec.File.Internal exposing
  ( toList
  , toBytes
  )

import Bytes exposing (Bytes)
import Bytes.Decode as Decode
import Bytes.Encode as Encode


toBytes : (a -> Encode.Encoder) -> List a -> Bytes
toBytes encoder ints =
  Encode.encode (Encode.sequence <| List.map encoder ints)


toList : Decode.Decoder a -> Bytes -> List a
toList decoder binaryContent =
  Decode.decode (listDecoder (Bytes.width binaryContent) decoder) binaryContent
    |> Maybe.withDefault []
    |> List.reverse


listDecoder : Int -> Decode.Decoder a -> Decode.Decoder (List a)
listDecoder width decoder =
  Decode.loop (width, []) (listStep decoder)


listStep : Decode.Decoder a -> (Int, List a) -> Decode.Decoder (Decode.Step (Int, List a) (List a))
listStep decoder (remaining, items) =
  if remaining == 0 then
    Decode.succeed (Decode.Done items)
  else
    Decode.map (\next -> Decode.Loop (remaining - 1, next :: items)) decoder
