module Spec.Http.Stub exposing
  ( HttpResponseStub
  , for
  , withBody
  )

import Spec.Http.Route exposing (HttpRoute)


type alias HttpResponseStub =
  { route: HttpRoute
  , body: Maybe String
  }


for : HttpRoute -> HttpResponseStub
for route =
  { route = route
  , body = Nothing
  }


withBody : String -> HttpResponseStub -> HttpResponseStub
withBody body stub =
  { stub | body = Just body }
