module Basic.Harness exposing (..)

import Harness exposing (Expectation, expect, use, run, toRun, observe, toObserve, setup, toSetup)
import Spec.Setup as Setup exposing (Setup)
import Spec.Step exposing (Step)
import Spec.Claim exposing (isSomethingWhere, isStringContaining)
import Spec.Observer as Observer
import Spec.Markup as Markup
import Spec.Markup.Selector exposing (..)
import Spec.Markup.Event as Event
import Spec.Http.Route exposing (get)
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
  [ ( "default", setup defaultSetup )
  , ( "withName", use setupConfigDecoder <| toSetup setupWithName )
  , ( "withStub", use Json.value <| toSetup setupWithStub )
  , ( "withInitialCommand", use (Json.list Json.string) <| toSetup setupWithInitialCommand )
  , ( "withInitialPortCommand", use (Json.list Json.string) <| toSetup setupWithInitialPortCommand )
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


steps =
  [ ( "click", use Json.int <| toRun clickMultiple )
  , ( "inform", run inform )
  , ( "requestStuff", run requestStuff )
  ]


-- Observers

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


observers =
  [ ("title", use Json.string <| toObserve titleObserver)
  , ("name", use Json.string <| toObserve nameObserver)
  , ("attributes", use (Json.list Json.string) <| toObserve attributesObserver)
  , ("count", use Json.string <| toObserve countObserver)
  , ("stuff", use Json.string <| toObserve stuffObserver)
  ]


main =
  Runner.harness <| setups ++ steps ++ observers