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
  , HttpResponseProgress
  , sent
  , received
  , streamed
  , withProgress
  )

{-| Define and set up stubs for HTTP requests made during a spec.

# Register Stubs
@docs HttpResponseStub, serve, nowServe

# Basic Stubs
@docs for, withBody, withStatus, withHeader

# Stubs for Requests in Progress
@docs HttpResponseProgress, sent, received, streamed, withProgress, abstain

# Stubs for Errors
@docs withNetworkError, withTimeout

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
    , error: Maybe String
    , progress: HttpResponseProgress
    }


{-| Represents progress on an in-flight HTTP request.
-}
type HttpResponseProgress
  = Complete
  | Sent Int
  | Received Int
  | Streamed Int


{-| Specify the number of bytes that have been uploaded to the server so far.
-}
sent : Int -> HttpResponseProgress
sent =
  Sent


{-| Specify the number of bytes received from the server so far.
-}
received : Int -> HttpResponseProgress
received =
  Received


{-| Specify the number of bytes received from the server so far, when the
total content length is not known.
-}
streamed : Int -> HttpResponseProgress
streamed =
  Streamed


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
    , error = Nothing
    , progress = Complete
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


{-| Set the progress on an in-flight HTTP request.

When the request is processed, an appropriate progress event will be triggered.

No further processing of this request will take place after the progress event is
triggered. So, use this function to describe a program's behavior when an HTTP request
is not yet complete.

-}
withProgress : HttpResponseProgress -> HttpResponseStub -> HttpResponseStub
withProgress responseProgress (HttpResponseStub stub) =
  HttpResponseStub
    { stub | progress = responseProgress }


{-| Abstain from responding to requests to the route defined for the given `HttpResponseStub`.

It can be useful to abstain from responding if you want to describe the behavior of your
program while waiting for a response.

Note: This function is equivalent to `withProgress <| received 0`

-}
abstain : HttpResponseStub -> HttpResponseStub
abstain =
  withProgress <| received 0


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
    , ( "progress", encodeProgress stub.progress )
    ]


encodeProgress : HttpResponseProgress -> Encode.Value
encodeProgress progress =
  case progress of
    Complete ->
      Encode.object [ ("type", Encode.string "complete" ) ]
    Sent transmitted ->
      encodeProgressType "sent" transmitted      
    Received transmitted ->
      encodeProgressType "received" transmitted
    Streamed transmitted ->
      encodeProgressType "streamed" transmitted


encodeProgressType : String -> Int -> Encode.Value
encodeProgressType progressType transmitted =
  Encode.object
    [ ("type", Encode.string progressType)
    , ("transmitted", Encode.int transmitted)
    ]


maybeEncodeString : Maybe String -> Encode.Value
maybeEncodeString maybeString =
  Maybe.withDefault "" maybeString
    |> Encode.string
