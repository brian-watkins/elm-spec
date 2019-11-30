module Spec.Http exposing
  ( HttpRequest
  , RequestBody
  , withStubs
  , observeRequests
  , hasHeader
  , hasStringBody
  , hasJsonBody
  )

import Spec.Subject as Subject exposing (SubjectProvider)
import Spec.Observer as Observer exposing (Observer)
import Spec.Claim as Claim exposing (Claim)
import Spec.Report as Report
import Spec.Message as Message exposing (Message)
import Spec.Http.Stub exposing (HttpResponseStub)
import Spec.Http.Route exposing (HttpRoute)
import Json.Encode as Encode
import Json.Decode as Json
import Dict exposing (Dict)


withStubs : List HttpResponseStub -> SubjectProvider model msg -> SubjectProvider model msg
withStubs stubs subjectProvider =
  List.foldl (\stub updatedSubject ->
    Subject.configure
      (httpStubMessage stub)
      updatedSubject
  ) (Subject.configure httpSetupMessage subjectProvider) stubs


httpStubMessage : HttpResponseStub -> Message
httpStubMessage stub =
  Message.for "_http" "stub"
    |> Message.withBody (encodeStub stub)


httpSetupMessage : Message
httpSetupMessage =
  Message.for "_http" "setup"


encodeStub : HttpResponseStub -> Encode.Value
encodeStub stub =
  Encode.object
    [ ( "method", Encode.string stub.route.method )
    , ( "url", Encode.string stub.route.url )
    , ( "status", Encode.int stub.response.status )
    , ( "headers", Encode.dict identity Encode.string stub.response.headers )
    , ( "body", maybeEncodeString stub.response.body )
    , ( "error", maybeEncodeString stub.error )
    , ( "shouldRespond", Encode.bool stub.shouldRespond )
    ]


maybeEncodeString : Maybe String -> Encode.Value
maybeEncodeString maybeString =
  Maybe.withDefault "" maybeString
    |> Encode.string


type alias HttpRequest =
  { url: String
  , headers: Dict String String
  , body: RequestBody
  }


type RequestBody
  = StringBody String


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


hasStringBody : String -> Claim HttpRequest
hasStringBody expected request =
  case request.body of
    StringBody actual ->
      if actual == expected then
        Claim.Accept
      else
        Claim.Reject <| Report.batch
          [ Report.fact "Expected request to have body with string" expected
          , Report.fact "but it has" actual
          ]


hasJsonBody : Json.Decoder a -> Claim a -> Claim HttpRequest
hasJsonBody decoder claim request =
  case request.body of
    StringBody actual ->
      case Json.decodeString decoder actual of
        Ok value ->
          claim value
        Err error ->
          Claim.Reject <| Report.batch
            [ Report.fact "Expected to decode request body as JSON" actual
            , Report.fact "but the decoder failed" <| Json.errorToString error
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
  Message.for "_http" "fetch-requests"
    |> Message.withBody (
      Encode.object
        [ ( "method", Encode.string route.method )
        , ( "url", Encode.string route.url )
        ]
    )


requestDecoder : Json.Decoder HttpRequest
requestDecoder =
  Json.map3 HttpRequest
    ( Json.field "url" Json.string )
    ( Json.field "headers" <| Json.dict Json.string )
    ( Json.field "body" requestBodyDecoder )


requestBodyDecoder : Json.Decoder RequestBody
requestBodyDecoder =
  Json.map StringBody Json.string