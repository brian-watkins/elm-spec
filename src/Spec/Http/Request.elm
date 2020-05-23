module Spec.Http.Request exposing
  ( HttpRequest
  , HttpRequestData(..)
  , Blob
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


type alias HttpRequest =
  { method: String
  , url: String
  , headers: Dict String String
  , body: HttpRequestData
  }


type HttpRequestData
  = NoData
  | TextData String
  | FileData File
  | BinaryData Blob
  | Multipart (List RequestDataPart)


type alias Blob =
  { mimeType: String
  , data: Bytes
  }


type alias RequestDataPart =
  { name: String
  , data: HttpRequestData
  }


toReport : List HttpRequest -> Report
toReport requests =
  if List.isEmpty requests then
    Report.note "No HTTP requests received"
  else
    List.map requestToReport requests
      |> List.append [ Report.note <| requestsReceived requests ]
      |> Report.batch


requestsReceived : List HttpRequest -> String
requestsReceived requests =
  if List.length requests == 1 then
    "Received 1 HTTP request"
  else
    "Received " ++ (String.fromInt <| List.length requests) ++ " HTTP requests"


requestToReport : HttpRequest -> Report
requestToReport request =
  headers request ++ "\n" ++ body request.body
    |> Report.fact (request.method ++ " " ++ request.url)


headers : HttpRequest -> String
headers request =
  "Headers: [ " ++ (headersToString ", " request) ++ " ]"


headersToString : String -> HttpRequest -> String
headersToString delimiter request =
  Dict.toList request.headers
    |> List.map (\(key, value) -> key ++ " = " ++ value)
    |> String.join delimiter


body : HttpRequestData -> String
body data =
  case data of
    NoData ->
      "Empty Body"
    TextData stringBody ->
      "Text data: " ++ stringBody
    FileData fileBody ->
      "File data with name: " ++ File.name fileBody
    BinaryData blob ->
      "Binary data of type " ++ blob.mimeType ++ " with " ++ (String.fromInt <| Bytes.width blob.data) ++ " bytes"
    Multipart parts ->
      "Multipart request with parts:\n" ++ (String.join "\n" <| List.map (\part -> part.name ++ " ==> " ++ body part.data) parts)


decoder : Json.Decoder HttpRequest
decoder =
  Json.map4 HttpRequest
    ( Json.field "methpd" Json.string )
    ( Json.field "url" Json.string )
    ( Json.field "headers" <| Json.dict Json.string )
    ( Json.field "body" ( Json.nullable requestBodyDecoder |> Json.map (Maybe.withDefault NoData) ) )


requestBodyDecoder : Json.Decoder HttpRequestData
requestBodyDecoder =
  Json.field "type" Json.string
    |> Json.andThen (\bodyType ->
      case bodyType of
        "file" ->
          Json.map FileData <|
            Json.field "content" File.decoder
        "bytes" ->
          Json.map BinaryData <|
            Json.map2 Blob
              (Json.field "mimeType" Json.string)
              (Json.field "data" Binary.jsonDecoder)
        "multipart" ->
          Json.map Multipart <|
            Json.field "parts" (Json.list bodyPartDecoder)
        _ ->
          Json.map TextData <|
            Json.field "content" Json.string
    )


bodyPartDecoder : Json.Decoder RequestDataPart
bodyPartDecoder =
  Json.map2 RequestDataPart
    ( Json.field "name" Json.string )
    ( Json.field "data" requestBodyDecoder )