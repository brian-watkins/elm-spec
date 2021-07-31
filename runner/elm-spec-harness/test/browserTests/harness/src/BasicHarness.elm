module BasicHarness exposing (..)

import Harness exposing (Expectation, expect)
import Spec.Setup as Setup exposing (Setup)
import Spec.Claim exposing (isSomethingWhere, isStringContaining)
import Spec.Observer as Observer
import Spec.Markup as Markup
import Spec.Markup.Selector exposing (..)
import Spec.Markup.Event as Event
import Extra exposing (equals)
import Runner
import Dict
import Json.Decode as Json
import App

-- Setup

type alias SetupConfiguration =
  { name: String
  }


setupConfigDecoder : Json.Decoder SetupConfiguration
setupConfigDecoder=
  Json.field "name" Json.string
    |> Json.map SetupConfiguration


defaultSetup : Json.Value -> Setup App.Model App.Msg
defaultSetup _ =
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


setups =
  Dict.fromList
    [ ( "default", Harness.exposeSetup Json.value defaultSetup )
    , ( "withName", Harness.exposeSetup setupConfigDecoder setupWithName )
    ]


-- Steps

clickMultiple =
  [ Markup.target << by [ id "counter-button" ]
  , Event.click
  , Event.click
  , Event.click
  ]


inform =
  [ Markup.target << by [ id "inform-button" ]
  , Event.click
  ]


steps =
  Dict.fromList
    [ ( "click", Harness.exposeSteps clickMultiple )
    , ( "inform", Harness.exposeSteps inform )
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


observers =
  Dict.fromList
    [ ("title", Harness.expose Json.string titleObserver)
    , ("name", Harness.expose Json.string nameObserver)
    , ("attributes", Harness.expose (Json.list Json.string) attributesObserver)
    , ("count", Harness.expose Json.string countObserver)
    ]


main =
  Runner.harness setups steps observers