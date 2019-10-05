module Spec.Http exposing
  ( HttpRequest
  , withStubs
  , expect
  )

import Spec.Subject as Subject exposing (SubjectGenerator)
import Spec.Observation as Observation exposing (Expectation)
import Spec.Observer as Observer exposing (Observer)
import Spec.Observation.Report as Report
import Spec.Message as Message exposing (Message)
import Spec.Http.Stub exposing (HttpResponseStub)
import Spec.Http.Route exposing (HttpRoute)
import Json.Encode as Encode
import Json.Decode as Json


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
  }


expect : HttpRoute -> Observer (List HttpRequest) -> Expectation model
expect route observer =
  Observation.inquire (fetchRequestsFor route)
    |> Observation.mapSelection (Message.decode <| Json.list requestDecoder)
    |> Observation.mapSelection (Maybe.withDefault [])
    |> Observation.expect (\requests ->
      observer requests
        |> Observer.mapRejection (
          Report.append <|
            Report.fact  "Observation rejected for route" <| route.method ++ " " ++ route.url
        )
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
  Json.map HttpRequest
    ( Json.field "url" Json.string )