module Spec.Http.Stub exposing
  ( HttpResponseStub
  , HttpStatus
  , for
  , withBody
  , withStatus
  , abstain
  )

import Spec.Http.Route exposing (HttpRoute)


type alias HttpResponseStub =
  { route: HttpRoute
  , response: HttpResponse
  , shouldRespond: Bool
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


abstain : HttpResponseStub -> HttpResponseStub
abstain stub =
  { stub | shouldRespond = False }