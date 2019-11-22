module Spec.Http exposing
  ( HttpRequest
  , withStubs
  , observeRequests
  , hasHeader
  , hasBody
  )

import Spec.Subject as Subject exposing (SubjectGenerator)
import Spec.Observer as Observer exposing (Observer)
import Spec.Claim as Claim exposing (Claim)
import Spec.Observation.Report as Report
import Spec.Message as Message exposing (Message)
import Spec.Http.Stub exposing (HttpResponseStub)
import Spec.Http.Route exposing (HttpRoute)
import Json.Encode as Encode
import Json.Decode as Json
import Dict exposing (Dict)


withStubs : List HttpResponseStub -> SubjectGenerator model msg -> SubjectGenerator model msg
withStubs stubs subjectGenerator =
  List.foldl (\stub updatedSubject ->
    Subject.configure
      { home = "_http"
      , name = "stub"
      , body = encodeStub stub
      }
      updatedSubject
  ) subjectGenerator stubs


encodeStub : HttpResponseStub -> Encode.Value
encodeStub stub =
  Encode.object
    [ ( "method", Encode.string stub.route.method )
    , ( "url", Encode.string stub.route.url )
    , ( "status", Encode.int stub.response.status )
    , ( "body", maybeEncodeString stub.response.body )
    ]


maybeEncodeString : Maybe String -> Encode.Value
maybeEncodeString maybeString =
  Maybe.withDefault "" maybeString
    |> Encode.string


type alias HttpRequest =
  { url: String
  , headers: Dict String String
  , body: String
  }


hasHeader : (String, String) -> Claim HttpRequest
hasHeader ( expectedName, expectedValue ) request =
  case Dict.get expectedName request.headers of
    Just actualValue ->
      if actualValue == expectedValue then
        Claim.Accept
      else
        rejectRequestForHeader (expectedName, expectedValue) request
    Nothing ->
      rejectRequestForHeader (expectedName, expectedValue) request


rejectRequestForHeader : (String, String) -> HttpRequest -> Claim.Verdict
rejectRequestForHeader ( expectedName, expectedValue ) request =
  Claim.Reject <| Report.batch
    [ Report.fact "Expected request to have header" <| expectedName ++ " = " ++ expectedValue
    , Report.fact "but it has" <| String.join "\n" <| List.map (\(k, v) -> k ++ " = " ++ v) <| Dict.toList request.headers
    ]


hasBody : String -> Claim HttpRequest
hasBody expectedBody request =
  if request.body == expectedBody then
    Claim.Accept
  else
    Claim.Reject <| Report.batch
      [ Report.fact "Expected request to have body" expectedBody
      , Report.fact "but it has" request.body
      ]


observeRequests : HttpRoute -> Observer model (List HttpRequest)
observeRequests route =
  Observer.inquire (fetchRequestsFor route) (
    Message.decode (Json.list requestDecoder)
      >> Maybe.withDefault []
  )
  |> Observer.mapRejection (
    Report.append <|
      Report.fact  "Claim rejected for route" <| route.method ++ " " ++ route.url
  )


fetchRequestsFor : HttpRoute -> Message
fetchRequestsFor route =
  { home = "_http"
  , name = "fetch-requests"
  , body =
      Encode.object
        [ ( "method", Encode.string route.method )
        , ( "url", Encode.string route.url )
        ]
  }


requestDecoder : Json.Decoder HttpRequest
requestDecoder =
  Json.map3 HttpRequest
    ( Json.field "url" Json.string )
    ( Json.field "headers" <| Json.dict Json.string )
    ( Json.field "body" Json.string )