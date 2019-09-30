module Spec.Http exposing
  ( withStubs
  )

import Spec.Subject as Subject exposing (Subject)
import Spec.Http.Stub exposing (HttpResponseStub)
import Json.Encode as Encode


withStubs : List HttpResponseStub -> Subject model msg -> Subject model msg
withStubs stubs subject =
  List.foldl (\stub updatedSubject ->
    Subject.configure
      { home = "_http"
      , name = "stub"
      , body = encodeStub stub
      }
      updatedSubject
  ) subject stubs


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