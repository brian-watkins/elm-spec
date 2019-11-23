module Spec.Http.Stub exposing
  ( HttpResponseStub
  , HttpStatus
  , for
  , withBody
  , withStatus
  , withNetworkError
  , withTimeout
  , abstain
  )

import Spec.Http.Route exposing (HttpRoute)


type alias HttpResponseStub =
  { route: HttpRoute
  , response: HttpResponse
  , shouldRespond: Bool
  , error: Maybe String
  }


type alias HttpResponse =
  { status: HttpStatus
  , body: Maybe String
  }


type alias HttpStatus =
  Int


for : HttpRoute -> HttpResponseStub
for route =
  { route = route
  , response =
      { status = 200
      , body = Nothing
      }
  , shouldRespond = True
  , error = Nothing
  }


withBody : String -> HttpResponseStub -> HttpResponseStub
withBody body stub =
  let
    response = stub.response
  in
    { stub | response = { response | body = Just body } }


withStatus : HttpStatus -> HttpResponseStub -> HttpResponseStub
withStatus status stub =
  let
    response = stub.response
  in
    { stub | response = { response | status = status } }


withNetworkError : HttpResponseStub -> HttpResponseStub
withNetworkError stub =
  { stub | error = Just "network" }


withTimeout : HttpResponseStub -> HttpResponseStub
withTimeout stub =
  { stub | error = Just "timeout" }


abstain : HttpResponseStub -> HttpResponseStub
abstain stub =
  { stub | shouldRespond = False }