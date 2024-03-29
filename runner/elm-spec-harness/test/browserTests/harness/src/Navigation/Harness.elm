module Navigation.Harness exposing (..)

import Harness exposing (Expectation, expect)
import Spec.Setup as Setup exposing (Setup)
import Spec.Step exposing (Step)
import Spec.Claim exposing (isSomethingWhere, isStringContaining)
import Spec.Observer as Observer
import Spec.Markup as Markup
import Spec.Markup.Selector exposing (..)
import Spec.Markup.Event as Event
import Spec.Navigator as Navigator
import Extra exposing (equals)
import Runner
import Dict
import Json.Decode as Json
import Json.Encode as Encode
import Url exposing (Url)
import Navigation.App as App


-- Setups

withNoNavigation : Setup App.Model App.Msg
withNoNavigation =
  Setup.initForApplication App.init
    |> Setup.withUpdate App.update
    |> Setup.withView App.view
    |> Setup.withSubscriptions App.subscriptions


setupWithInitialLocation : String -> Setup App.Model App.Msg
setupWithInitialLocation location =
  Setup.initForApplication App.init
    |> Setup.withUpdate App.update
    |> Setup.withView App.view
    |> Setup.withSubscriptions App.subscriptions
    |> Setup.forNavigation { onUrlRequest = App.OnUrlRequest, onUrlChange = App.OnUrlChange }
    |> Setup.withLocation (urlFrom location)


urlFrom : String -> Url
urlFrom location =
  Url.fromString location
    |> Maybe.withDefault defaultUrl


defaultUrl =
  { protocol = Url.Http
  , host = "blah.com"
  , port_ = Nothing
  , path = "/"
  , query = Nothing
  , fragment = Nothing
  }


setups =
  [ Harness.define "withLocation" Json.string setupWithInitialLocation
  , Harness.assign "withNoNavigation" withNoNavigation
  ]


-- Steps


gotoAwesome =
  [ Markup.target << by [ id "awesome-location" ]
  , Event.click
  ]


clickLinkToChangeLocation =
  [ Markup.target << by [ id "super-link" ]
  , Event.click
  ]


clickLinkToLeaveApp =
  [ Markup.target << by [ id "external-link" ]
  , Event.click
  ]


stepsToExpose =
  [ Harness.assign "gotoAwesome" gotoAwesome
  , Harness.assign "clickLinkToChangeLocation" clickLinkToChangeLocation
  , Harness.assign "clickLinkToLeaveApp" clickLinkToLeaveApp
  ]


-- Observers

titleObserver : String -> Expectation App.Model
titleObserver actual =
  Markup.observeElement
    |> Markup.query << by [ id "title" ]
    |> expect (isSomethingWhere <| Markup.text <| isStringContaining 1 actual)


locationObserver : String -> Expectation App.Model
locationObserver expected =
  Navigator.observe
    |> expect (Navigator.location <| equals expected)


pageText : String -> Expectation App.Model
pageText expected =
  Markup.observeElement
    |> Markup.query << by [ tag "body" ]
    |> expect (isSomethingWhere <| Markup.text <| isStringContaining 1 expected)


observers =
  [ Harness.define "title" Json.string titleObserver
  , Harness.define "location" Json.string locationObserver
  , Harness.define "pageText" Json.string pageText
  ]


main =
  Runner.harness
    { initialStates = setups
    , scripts = stepsToExpose
    , expectations = observers
    }