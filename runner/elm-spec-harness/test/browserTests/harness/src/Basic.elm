module Basic exposing (..)

import Harness exposing (Expectation, expect)
import Spec.Setup as Setup
import Spec.Claim exposing (isSomethingWhere, isStringContaining)
import Spec.Observer as Observer
import Spec.Markup as Markup
import Spec.Markup.Selector exposing (..)
import Extra exposing (equals)
import Runner
import Dict
import Json.Decode as Json
import App

-- Setup

setup =
  Setup.initWithModel App.defaultModel
    |> Setup.withUpdate App.update
    |> Setup.withView App.view

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


observers =
  Dict.fromList
    [ ("title", Harness.expose Json.string titleObserver)
    , ("name", Harness.expose Json.string nameObserver)
    , ("attributes", Harness.expose (Json.list Json.string) attributesObserver)
    ]


main =
  Runner.harness setup observers