module Spec.Http.Stub exposing
  ( HttpResponseStub
  , serve
  , nowServe
  , for
  , HttpResponseBody
  , withBody
  , withBytes
  , withText
  , withJson
  , withBytesAtPath
  , withTextAtPath
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
  , Contract
  , openApiContractAt
  , satisfies
  )

{-| Define and set up stubs for HTTP requests made during a spec.

If an HTTP request matches none of the stubs currently served, then
elm-spec will respond with a `404` status code.

# Create and Register Stubs
@docs HttpResponseStub, for, serve, nowServe

# Stub the Response Body
@docs HttpResponseBody, withBody, withText, withJson, withBytes, withTextAtPath, withBytesAtPath

# Stub Progress of an In-Flight Request
@docs HttpResponseProgress, sent, received, streamed, withProgress, abstain

# Stub Response Metadata
@docs withStatus, withHeader

# Stub Errors
@docs withNetworkError, withTimeout

# Work with API Contracts

When you create stubs as part of a spec, you are simluating an HTTP API and thus making
assumptions about the shape of that API -- what paths it defines, what response
bodies should look like, what headers are required, etc. Without some external
validation, it's easy to imagine that the assumptions made in your specs could fall
out of sync with reality.

An API contract, like an OpenAPI document, can help you avoid this situation. An
API contract describes the shape of an API in a format that can be shared by all
parties interested in that API, so that each party -- the server, a mobile client,
a web client, etc -- can check their own assumptions about that API against the very
same description.

Use the functions below to create and associate an API contract with a stub so that all
requests matching that stub and all responses returned by that stub are validated
against that contract. By following this pattern, you can be confident that your stubs
accurately describe the API integration they are simulating.

@docs Contract, satisfies, openApiContractAt

-}

import Spec.Setup as Setup exposing (Setup)
import Spec.Setup.Internal as Setup
import Spec.Step as Step
import Spec.Step.Command as Command
import Spec.Message as Message exposing (Message)
import Spec.Http.Route as Route exposing (HttpRoute)
import Dict exposing (Dict)
import Json.Encode as Encode
import Bytes exposing (Bytes)
import Spec.Binary as Binary
import Dict


{-| Represents the stubbed response for a particular HTTP request.
-}
type HttpResponseStub =
  HttpResponseStub
    { route: HttpRoute
    , response: HttpResponse
    , error: Maybe String
    , progress: HttpResponseProgress
    , contract: Maybe Contract
    }


{-| Represents progress on an in-flight HTTP request.
-}
type HttpResponseProgress
  = Complete
  | Sent Int
  | Received Int
  | Streamed Int


{-| Specify the number of bytes that have been uploaded to the server so far.

Note that the total number of bytes is determined by the HTTP request body.
-}
sent : Int -> HttpResponseProgress
sent =
  Sent


{-| Specify the number of bytes received from the server so far.

Note that the total number of bytes is determined by the stubbed HTTP response body.
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
  , body: HttpResponseBody
  }

{-| Represents the body of an HTTP response.
-}
type HttpResponseBody
  = Empty
  | Text String
  | Binary Bytes
  | BytesFromFile String
  | TextFromFile String


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
        , body = Empty
        }
    , error = Nothing
    , progress = Complete
    , contract = Nothing
    }


{-| Supply an `HttpResponseBody` for the stubbed response.
-}
withBody : HttpResponseBody -> HttpResponseStub -> HttpResponseStub
withBody body =
  mapResponse <| \response ->
    { response | body = body }


{-| Create an `HttpResponseBody` composed of the given text.
-}
withText : String -> HttpResponseBody
withText =
  Text


{-| Create an `HttpResponseBody` composed of the given JSON value, stringified.
-}
withJson : Encode.Value -> HttpResponseBody
withJson value =
  Encode.encode 0 value
    |> Text


{-| Create an `HttpResponseBody` composed of the given bytes.
-}
withBytes : Bytes -> HttpResponseBody
withBytes =
  Binary


{-| Create an `HttpResponseBody` composed of the bytes from the file at the given path.

The path is typically relative to the current working directory of the elm-spec runner (but
check the docs for the runner you are using).
-}
withBytesAtPath : String -> HttpResponseBody
withBytesAtPath =
  BytesFromFile


{-| Create an `HttpResponseBody` composed of the text from the file at the given path.

The path is typically relative to the current working directory of the elm-spec runner (but
check the docs for the runner you are using).
-}
withTextAtPath : String -> HttpResponseBody
withTextAtPath =
  TextFromFile


{-| Supply a status code for the stubbed response.
-}
withStatus : Int -> HttpResponseStub -> HttpResponseStub
withStatus status  =
  mapResponse <| \response ->
    { response | status = status }


{-| Supply a header (key, value) for the stubbed response.
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
  contractsFor stubs
    |> registerContracts
    |> Setup.configurationRequest (\_ -> Setup.SendMessage <| httpStubMessage stubs)


contractsFor : List HttpResponseStub -> List Contract
contractsFor stubs =
  List.filterMap (\(HttpResponseStub stub) -> stub.contract) stubs
    |> List.map (\(Contract contract) -> ( contract.path, Contract contract ))
    |> Dict.fromList
    |> Dict.values


registerContracts : List Contract -> Message
registerContracts contracts =
  Message.for "_http" "contracts"
    |> Message.withBody (Encode.object
      [ ("contracts", Encode.list encodeContract contracts)
      ]
    )


{-| A step that reconfigures the fake HTTP server to serve the given `HttpResponseStubs`.

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
nowServe : List HttpResponseStub -> Step.Step model msg
nowServe stubs =
  \_ ->
    contractsFor stubs
      |> registerContracts
      |> Command.sendRequest (\_ -> Command.sendMessage <| httpStubMessage stubs)


{-| Specify a contract that should be used to validate requests that match this
stub as well as the response returned.

Consider creating a function that makes it easy to write stubs that should satisfy
a particular contract:

    funApiStubFor : HttpRoute -> HttpResponseStub
    funApiStubFor route =
      Stub.for route
        |> Stub.satisfies funApiContract

Then you can use `funApiStubFor` anywhere you would use `Spec.Http.Stub.for` to define
a stub.

-}
satisfies : Contract -> HttpResponseStub -> HttpResponseStub
satisfies contract (HttpResponseStub stub) =
  HttpResponseStub
    { stub | contract = Just contract }


{-| Represents a contract with repsect to which HTTP requests and responses
can be validated.
-}
type Contract =
  Contract
    { path: String
    }


{-| Create a Contract from an OpenAPI document at the given path.

[OpenAPI version 2.0 (Swagger)](https://swagger.io/specification/v2/)
and [OpenAPI version 3.0](https://swagger.io/specification/) are supported.
The document can be in YAML or JSON format.

The path is typically relative to the current working directory of the elm-spec
runner (but check the docs for the runner you are using).
-}
openApiContractAt : String -> Contract
openApiContractAt path =
  Contract
    { path = path
    }


encodeContract : Contract -> Encode.Value
encodeContract (Contract contract) =
  Encode.object
    [ ( "path", Encode.string contract.path )
    ]


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
    , ( "body", encodeBody stub.response.body )
    , ( "error", maybeEncode Encode.string stub.error )
    , ( "progress", encodeProgress stub.progress )
    , ( "contract", maybeEncode encodeContract stub.contract )
    ]


encodeBody : HttpResponseBody -> Encode.Value
encodeBody body =
  case body of
    Empty ->
      Encode.object [ ("type", Encode.string "empty") ]
    Text text ->
      Encode.object
        [ ("type", Encode.string "text")
        , ("content", Encode.string text)
        ]
    Binary bytes ->
      Encode.object
        [ ("type", Encode.string "binary")
        , ("content", Binary.jsonEncode bytes)
        ]
    BytesFromFile path ->
      Encode.object
        [ ("type", Encode.string "bytesFromFile")
        , ("path", Encode.string path)
        ]
    TextFromFile path ->
      Encode.object
        [ ("type", Encode.string "textFromFile")
        , ("path", Encode.string path)
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


maybeEncode : (a -> Encode.Value) -> Maybe a -> Encode.Value
maybeEncode encoder maybeValue =
  Maybe.map encoder maybeValue
    |> Maybe.withDefault Encode.null