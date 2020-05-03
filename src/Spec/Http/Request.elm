module Spec.Http.Request exposing
  ( RequestData
  , RequestBody(..)
  , toReport
  , headersToString
  , decoder
  )

import Spec.Report as Report exposing (Report)
import Spec.Binary as Binary
import Json.Decode as Json
import File exposing (File)
import Dict exposing (Dict)
import Bytes exposing (Bytes)


type alias RequestData =
  { method: String
  , url: String
  , headers: Dict String String
  , body: RequestBody
  }


type RequestBody
  = EmptyBody
  | StringBody String
  | FileBody File
  | BytesBody Bytes


toReport : List RequestData -> Report
toReport requests =
  if List.isEmpty requests then
    Report.note "No HTTP requests received"
  else
    List.map requestDataToReport requests
      |> List.append [ Report.note <| requestsReceived requests ]
      |> Report.batch


requestsReceived : List RequestData -> String
requestsReceived requests =
  if List.length requests == 1 then
    "Received 1 HTTP request"
  else
    "Received " ++ (String.fromInt <| List.length requests) ++ " HTTP requests"


requestDataToReport : RequestData -> Report
requestDataToReport data =
  headers data ++ "\n" ++ body data
    |> Report.fact (data.method ++ " " ++ data.url)


headers : RequestData -> String
headers data =
  "Headers: [ " ++ (headersToString ", " data) ++ " ]"


headersToString : String -> RequestData -> String
headersToString delimiter data =
  Dict.toList data.headers
    |> List.map (\(key, value) -> key ++ " = " ++ value)
    |> String.join delimiter


body : RequestData -> String
body data =
  case data.body of
    EmptyBody ->
      "Empty Body"
    StringBody stringBody ->
      "Body: " ++ stringBody
    FileBody fileBody ->
      "File Body with name: " ++ File.name fileBody
    BytesBody binaryContent ->
      "Bytes Body with " ++ (String.fromInt <| Bytes.width binaryContent) ++ " bytes"


decoder : Json.Decoder RequestData
decoder =
  Json.map4 RequestData
    ( Json.field "methpd" Json.string )
    ( Json.field "url" Json.string )
    ( Json.field "headers" <| Json.dict Json.string )
    ( Json.field "body" ( Json.nullable requestBodyDecoder |> Json.map (Maybe.withDefault EmptyBody) ) )


requestBodyDecoder : Json.Decoder RequestBody
requestBodyDecoder =
  Json.field "type" Json.string
    |> Json.andThen (\bodyType ->
      case bodyType of
        "file" ->
          Json.field "content" File.decoder
            |> Json.map FileBody
        "bytes" ->
          Json.field "data" Binary.jsonDecoder
            |> Json.map BytesBody
        _ ->
          Json.field "content" Json.string
            |> Json.map StringBody
    )
