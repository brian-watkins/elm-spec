module Spec.Http.Stub exposing
  ( HttpResponseStub
  , serve
  , for
  , withBody
  , withStatus
  , withHeader
  , withNetworkError
  , withTimeout
  , abstain
  )

{-| Define and set up stubs for HTTP requests made during a spec.

# Set Up Stubs
@docs HttpResponseStub, serve

# Define Stubs
@docs for, withBody, withStatus, withHeader, withNetworkError, withTimeout, abstain

-}

import Spec.Setup as Setup exposing (Setup)
import Spec.Setup.Internal as Setup
import Spec.Message as Message exposing (Message)
import Spec.Http.Route exposing (HttpRoute)
import Dict exposing (Dict)
import Json.Encode as Encode


{-| Represents the stubbed response for a particular HTTP request.
-}
type HttpResponseStub =
  HttpResponseStub
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


{-| Build a stubbed response for requests made to the given route.

By default, the stubbed response has:

- 200 status code
- no headers
- no body

-}
for : HttpRoute -> HttpResponseStub
for route =
  HttpResponseStub
    { route = route
    , response =
        { status = 200
        , headers = Dict.empty
        , body = Nothing
        }
    , shouldRespond = True
    , error = Nothing
    }


{-| Supply a body for the stubbed response.
-}
withBody : String -> HttpResponseStub -> HttpResponseStub
withBody body =
  mapResponse <| \response ->
    { response | body = Just body }


{-| Supply a status code for the stubbed response.
-}
withStatus : Int -> HttpResponseStub -> HttpResponseStub
withStatus status  =
  mapResponse <| \response ->
    { response | status = status }


{-| Supple a header (key, value) for the stubbed response.
-}
withHeader : (String, String) -> HttpResponseStub -> HttpResponseStub
withHeader ( name, value ) =
  mapResponse <| \response ->
    { response | headers = Dict.insert name value response.headers }


mapResponse : (HttpResponse -> HttpResponse) -> HttpResponseStub -> HttpResponseStub
mapResponse mapper (HttpResponseStub stub) =
  HttpResponseStub
    { stub | response = mapper stub.response }


{-| Set the stubbed response to trigger a network error.
-}
withNetworkError : HttpResponseStub -> HttpResponseStub
withNetworkError (HttpResponseStub stub) =
  HttpResponseStub
    { stub | error = Just "network" }


{-| Set the stubbed response to trigger a timeout error.
-}
withTimeout : HttpResponseStub -> HttpResponseStub
withTimeout (HttpResponseStub stub) =
  HttpResponseStub
    { stub | error = Just "timeout" }


{-| Abstain from responding to requests to the route defined for the given `HttpResponseStub`.

It can be useful to abstain from responding if you want to describe the behavior of your
program while waiting for a response.
-}
abstain : HttpResponseStub -> HttpResponseStub
abstain (HttpResponseStub stub) =
  HttpResponseStub
    { stub | shouldRespond = False }


{-| Set up a fake HTTP server to serve a stubbed response when a matching request is made.
-}
serve : List HttpResponseStub -> Setup model msg -> Setup model msg
serve stubs subjectProvider =
  List.foldl (\stub updatedSubject ->
    Setup.configure
      (httpStubMessage stub)
      updatedSubject
  ) (Setup.configure httpSetupMessage subjectProvider) stubs


httpStubMessage : HttpResponseStub -> Message
httpStubMessage stub =
  Message.for "_http" "stub"
    |> Message.withBody (encodeStub stub)


httpSetupMessage : Message
httpSetupMessage =
  Message.for "_http" "setup"


encodeStub : HttpResponseStub -> Encode.Value
encodeStub (HttpResponseStub stub) =
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
