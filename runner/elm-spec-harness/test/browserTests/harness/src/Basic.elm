module Basic exposing (..)

import Harness exposing (Expectation, expect)
import Spec.Setup as Setup
import Spec.Claim exposing (isSomethingWhere, isStringContaining)
import Spec.Observer as Observer
import Spec.Markup as Markup
import Spec.Markup.Selector exposing (..)
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


modelObserver : String -> Expectation App.Model
modelObserver actual =
  Observer.observeModel .name
    |> expect (isStringContaining 1 actual)


observers =
  Dict.fromList
    [ ("title", Harness.expose Json.string titleObserver)
    , ("name", Harness.expose Json.string modelObserver)
    ]


main =
  Runner.harness setup observers