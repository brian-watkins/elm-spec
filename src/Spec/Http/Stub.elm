module Spec.Http.Stub exposing
  ( HttpResponseStub
  , HttpStatus
  , for
  , withBody
  , withStatus
  , withHeader
  , withNetworkError
  , withTimeout
  , abstain
  )

import Spec.Http.Route exposing (HttpRoute)
import Dict exposing (Dict)


type alias HttpResponseStub =
  { route: HttpRoute
  , response: HttpResponse
  , shouldRespond: Bool
  , error: Maybe String
  }


type alias HttpResponse =
  { status: HttpStatus
  , headers: Dict String String
  , body: Maybe String
  }


type alias HttpStatus =
  Int


for : HttpRoute -> HttpResponseStub
for route =
  { route = route
  , response =
      { status = 200
      , headers = Dict.empty
      , body = Nothing
      }
  , shouldRespond = True
  , error = Nothing
  }


withBody : String -> HttpResponseStub -> HttpResponseStub
withBody body =
  mapResponse <| \response ->
    { response | body = Just body }


withStatus : HttpStatus -> HttpResponseStub -> HttpResponseStub
withStatus status  =
  mapResponse <| \response ->
    { response | status = status }


withHeader : (String, String) -> HttpResponseStub -> HttpResponseStub
withHeader ( name, value ) =
  mapResponse <| \response ->
    { response | headers = Dict.insert name value response.headers }


mapResponse : (HttpResponse -> HttpResponse) -> HttpResponseStub -> HttpResponseStub
mapResponse mapper stub =
  { stub | response = mapper stub.response }


withNetworkError : HttpResponseStub -> HttpResponseStub
withNetworkError stub =
  { stub | error = Just "network" }


withTimeout : HttpResponseStub -> HttpResponseStub
withTimeout stub =
  { stub | error = Just "timeout" }


abstain : HttpResponseStub -> HttpResponseStub
abstain stub =
  { stub | shouldRespond = False }