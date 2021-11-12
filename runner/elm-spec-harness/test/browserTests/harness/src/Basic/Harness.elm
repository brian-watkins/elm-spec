module Basic.Harness exposing (..)

import Harness exposing (Expectation, expect)
import Spec.Setup as Setup exposing (Setup)
import Spec.Step exposing (Step)
import Spec.Claim exposing (isSomethingWhere, isStringContaining, isListWithLength)
import Spec.Observer as Observer
import Spec.Markup as Markup
import Spec.Markup.Selector exposing (..)
import Spec.Markup.Event as Event
import Spec.Http
import Spec.Http.Route exposing (get, route, UrlDescriptor(..))
import Spec.Http.Stub as Stub
import Extra exposing (equals)
import Runner
import Dict
import Json.Decode as Json
import Json.Encode as Encode
import Basic.App as App

-- Setup

type alias SetupConfiguration =
  { name: String
  }


setupConfigDecoder : Json.Decoder SetupConfiguration
setupConfigDecoder=
  Json.field "name" Json.string
    |> Json.map SetupConfiguration


defaultSetup : Setup App.Model App.Msg
defaultSetup =
  Setup.initWithModel App.defaultModel
    |> Setup.withUpdate App.update
    |> Setup.withView App.view
    |> Setup.withSubscriptions App.subscriptions
    |> Stub.serve
      [ stuffStub <| Encode.object
        [ ( "thing", Encode.string "apples")
        , ("count", Encode.int 91)
        ]
      ]


setupWithName : SetupConfiguration -> Setup App.Model App.Msg
setupWithName config =
  let
    model = App.defaultModel
  in
    Setup.initWithModel { model | name = config.name }
      |> Setup.withUpdate App.update
      |> Setup.withView App.view
      |> Setup.withSubscriptions App.subscriptions


stuffStub stuff =
  Stub.for (get "http://fake.com/fakeStuff")
    |> Stub.withBody (Stub.withJson stuff)


setupWithStub : Json.Value -> Setup App.Model App.Msg
setupWithStub stuff =
  Setup.initWithModel App.defaultModel
    |> Setup.withUpdate App.update
    |> Setup.withView App.view
    |> Setup.withSubscriptions App.subscriptions
    |> Stub.serve [ stuffStub stuff ]


setupWithContract : String -> Setup App.Model App.Msg
setupWithContract contractPath =
  Setup.initWithModel App.defaultModel
    |> Setup.withUpdate App.update
    |> Setup.withView App.view
    |> Setup.withSubscriptions App.subscriptions
    |> Stub.serve [ stuffStub (Encode.object []) |> Stub.satisfies (Stub.openApiContractAt contractPath) ]


setupWithInitialCommand : List String -> Setup App.Model App.Msg
setupWithInitialCommand attributes =
  Setup.init (App.init attributes)
    |> Setup.withUpdate App.update
    |> Setup.withView App.view
    |> Setup.withSubscriptions App.subscriptions
    |> Stub.serve [ stuffStub <| Encode.object [ ("thing", Encode.string <| String.join ", " attributes), ("count", Encode.int <| List.length attributes) ] ]


setupWithInitialPortCommand : List String -> Setup App.Model App.Msg
setupWithInitialPortCommand attributes =
  Setup.init (App.initWithPort attributes)
    |> Setup.withUpdate App.update
    |> Setup.withView App.view
    |> Setup.withSubscriptions App.subscriptions


setups =
  [ Harness.assign "default" defaultSetup
  , Harness.define "withName" setupConfigDecoder setupWithName
  , Harness.define "withStub" Json.value setupWithStub
  , Harness.define "withHttpContract" Json.string setupWithContract
  , Harness.define "withInitialCommand" (Json.list Json.string) setupWithInitialCommand
  , Harness.define "withInitialPortCommand" (Json.list Json.string) setupWithInitialPortCommand
  ]


-- Steps

clickMultiple : Int -> List (Step model msg)
clickMultiple times =
  [ Markup.target << by [ id "counter-button" ] ]
    ++ (List.repeat times Event.click)


inform =
  [ Markup.target << by [ id "inform-button" ]
  , Event.click
  ]


requestStuff =
  [ Markup.target << by [ id "send-request" ]
  , Event.click
  ]


logTitle =
  [ Markup.log << by [ id "title" ]
  ]


badSteps =
  [ Markup.target << by [ id "some-element-that-does-not-exist" ]
  , Event.click
  ]

stepsToExpose =
  [ Harness.assign "inform" inform
  , Harness.define "click" Json.int clickMultiple
  , Harness.assign "requestStuff" requestStuff
  , Harness.assign "logTitle" logTitle
  , Harness.assign "badSteps" badSteps
  ]


-- Expectations

titleObserver : String -> Expectation App.Model
titleObserver actual =
  Markup.observeElement
    |> Markup.query << by [ id "title" ]
    |> expect (isSomethingWhere <| Markup.text <| isStringContaining 1 actual)


nameObserver : String -> Expectation App.Model
nameObserver actual =
  Observer.observeModel .name
    |> expect (isStringContaining 1 actual)


attributesObserver : List String -> Expectation App.Model
attributesObserver actual =
  Observer.observeModel .attributes
    |> expect (equals actual)


countObserver : String -> Expectation App.Model
countObserver actual =
  Markup.observeElement
    |> Markup.query << by [ id "counter-status" ]
    |> expect (isSomethingWhere <| Markup.text <| isStringContaining 1 actual)


stuffObserver : String -> Expectation App.Model
stuffObserver actual =
  Markup.observeElement
    |> Markup.query << by [ id "stuff-description" ]
    |> expect (isSomethingWhere <| Markup.text <| isStringContaining 1 actual)


requestsMatching : ExpectedRequestsMatching -> Expectation App.Model
requestsMatching expected =
  Spec.Http.observeRequests (route "GET" <| Matching expected.regex)
    |> expect (isListWithLength expected.count)


type alias ExpectedRequestsMatching =
  { regex: String
  , count: Int
  }


requestsMatchingDecoder : Json.Decoder ExpectedRequestsMatching
requestsMatchingDecoder =
  Json.map2 ExpectedRequestsMatching
    ( Json.field "regex" Json.string )
    ( Json.field "count" Json.int )


expectations =
  [ Harness.define "title" Json.string titleObserver
  , Harness.define "name" Json.string nameObserver
  , Harness.define "attributes" (Json.list Json.string) attributesObserver
  , Harness.define "count" Json.string countObserver
  , Harness.define "stuff" Json.string stuffObserver
  , Harness.define "requestsMatching" requestsMatchingDecoder requestsMatching
  ]


main =
  Runner.harness
    { initialStates = setups
    , scripts = stepsToExpose
    , expectations = expectations
    }