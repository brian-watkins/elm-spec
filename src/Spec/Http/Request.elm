module Spec.Http.Request exposing
  ( RequestData
  , RequestBody(..)
  , toReport
  , headersToString
  , decoder
  )

import Spec.Report as Report exposing (Report)
import Json.Decode as Json
import Dict exposing (Dict)


type alias RequestData =
  { method: String
  , url: String
  , headers: Dict String String
  , body: RequestBody
  }


type RequestBody
  = EmptyBody
  | StringBody String


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


decoder : Json.Decoder RequestData
decoder =
  Json.map4 RequestData
    ( Json.field "methpd" Json.string )
    ( Json.field "url" Json.string )
    ( Json.field "headers" <| Json.dict Json.string )
    ( Json.field "body" requestBodyDecoder )


requestBodyDecoder : Json.Decoder RequestBody
requestBodyDecoder =
  Json.nullable Json.string
    |> Json.map (\maybeBody ->
      Maybe.map StringBody maybeBody
        |> Maybe.withDefault EmptyBody
    )
