module Spec.Http.Stub exposing
  ( HttpResponseStub
  , serve
  , nowServe
  , for
  , withBody
  , withStatus
  , withHeader
  , withNetworkError
  , withTimeout
  , abstain
  )

{-| Define and set up stubs for HTTP requests made during a spec.

# Register Stubs
@docs HttpResponseStub, serve, nowServe

# Define Stubs
@docs for, withBody, withStatus, withHeader, withNetworkError, withTimeout, abstain

-}

import Spec.Setup as Setup exposing (Setup)
import Spec.Setup.Internal as Setup
import Spec.Step as Step
import Spec.Step.Command as Command
import Spec.Message as Message exposing (Message)
import Spec.Http.Route as Route exposing (HttpRoute)
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


{-| Set up a fake HTTP server with the given `HttpResponseStubs`.

When a matching HTTP request is made, the relevant stubbed response will be returned.
-}
serve : List HttpResponseStub -> Setup model msg -> Setup model msg
serve stubs =
  Setup.configure <| httpStubMessage stubs


{-| Reconfigure the fake HTTP server to serve the given `HttpResponseStubs`.

Use this function if you want to change the stubs during a scenario.

For example, suppose you are writing a scenario that describes an application that
polls some HTTP endpoint every 5 seconds. You could change the stubbed response
during the scenario like so:

    Spec.scenario "polling" (
      Spec.given (
        Spec.Setup.init (App.init testFlags)
          |> Spec.Setup.withView App.view
          |> Spec.Setup.withUpdate App.update
          |> Stub.serve [ pollFailsStub ]
      )
      |> when "time passes"
        [ Spec.Time.tick 5000
        , Spec.Time.tick 5000
        ]
      |> when "the poll succeeds"
        [ Spec.Http.Stub.nowServe [ pollSucceedsStub ]
        , Spec.Time.tick 5000
        ]
      |> it "does the right thing" (
        ...
      )
    )

Note that `Spec.Http.Stub.nowServe` will clear any existing stubs and
register only the ones provided.

-}
nowServe : List HttpResponseStub -> Step.Context model -> Step.Command msg
nowServe stubs _ =
  Command.sendMessage <| httpStubMessage stubs


httpStubMessage : List HttpResponseStub -> Message
httpStubMessage stubs =
  Message.for "_http" "stub"
    |> Message.withBody (Encode.list encodeStub stubs)


encodeStub : HttpResponseStub -> Encode.Value
encodeStub (HttpResponseStub stub) =
  Encode.object
    [ ( "route", Route.encode stub.route )
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
