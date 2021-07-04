module Specs.NavigationSpec exposing (..)

import Spec exposing (..)
import Spec.Setup as Setup
import Spec.Markup as Markup
import Spec.Markup.Selector exposing (..)
import Spec.Markup.Event as Event
import Spec.Navigator as Navigator
import Spec.Claim exposing (isSomethingWhere)
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Browser.Navigation
import Runner
import Url
import Task
import Specs.Helpers exposing (..)


loadUrlSpec : Spec Model Msg
loadUrlSpec =
  Spec.describe "a program that uses Browser.Navigation.loadUrl"
  [ scenario "a new URL is loaded" (
      given (
        Setup.initWithModel ()
          |> Setup.withView testView
          |> Setup.withUpdate testUpdate
          |> Setup.withLocation testUrl
      )
      |> when "a new page load is triggered"
        [ Markup.target << by [ id "load-button" ]
        , Event.click
        ]
      |> observeThat
        [ it "updates the document location" (
            Navigator.observe
              |> expect (Navigator.location <| equals "http://navigation-test-app.com/some-fun-place")
          )
        , it "shows a view that says we navigated outside the scope of the Elm program" (
            Markup.observeElement
              |> Markup.query << by [ tag "body" ]
              |> expect (isSomethingWhere <|
                Markup.text <| equals "[Navigated to a page outside the control of the Elm program: http://navigation-test-app.com/some-fun-place]"
              )
          )
        ]
    )
  , scenario "a URL is loaded with the same path but a different origin" (
      given (
        Setup.initWithModel ()
          |> Setup.withView testView
          |> Setup.withUpdate testUpdate
          |> Setup.withLocation testUrl
      )
      |> when "a new page load is triggered"
        [ Markup.target << by [ id "load-same-path-button" ]
        , Event.click
        ]
      |> observeThat
        [ it "updates the document location" (
            Navigator.observe
              |> expect (Navigator.location <| equals "http://some-other-spot.com/")
          )
        , it "shows a view that says we navigated outside the scope of the Elm program" (
            Markup.observeElement
              |> Markup.query << by [ tag "body" ]
              |> expect (isSomethingWhere <|
                Markup.text <| equals "[Navigated to a page outside the control of the Elm program: http://some-other-spot.com/]"
              )
          )
        ]
    )
  , scenario "checking the default location" (
      given (
        Setup.initWithModel ()
          |> Setup.withView testView
          |> Setup.withUpdate testUpdate
          |> Setup.withLocation testUrl
      )
      |> it "shows the default location" (
        Navigator.observe
          |> expect (Navigator.location <| equals "http://navigation-test-app.com/")
      )
    )
  ]


testUrl =
  { protocol = Url.Http
  , host = "navigation-test-app.com"
  , port_ = Nothing
  , path = "/"
  , query = Nothing
  , fragment = Nothing
  }


reloadSpec : Spec Model Msg
reloadSpec =
  Spec.describe "a program that reloads the page"
  [ scenario "Browser.Navigation.reload is used" (
      given (
        Setup.initWithModel ()
          |> Setup.withView testView
          |> Setup.withUpdate testUpdate
      )
      |> when "a reload is triggered"
        [ Markup.target << by [ id "reload-button" ]
        , Event.click
        ]
      |> it "records the reload" (
        Navigator.expectReload
      )
    )
  , scenario "Browser.Navigation.reloadAndSkipCache is used" (
      given (
        Setup.initWithModel ()
          |> Setup.withView testView
          |> Setup.withUpdate testUpdate
      )
      |> when "a reload is triggered"
        [ Markup.target << by [ id "reload-skip-cache-button" ]
        , Event.click
        ]
      |> it "records the reload" (
        Navigator.expectReload
      )
    )
  , scenario "the page has not been reloaded" (
      given (
        Setup.initWithModel ()
          |> Setup.withView testView
          |> Setup.withUpdate testUpdate
      )
      |> it "records the reload" (
        Navigator.expectReload
      )
    )
  ]


batchLoadSpec : Spec Model Msg
batchLoadSpec =
  Spec.describe "batching load with another command"
  [ scenario "load and something else" (
      given (
        Setup.initWithModel ()
          |> Setup.withView testView
          |> Setup.withUpdate testUpdate
          |> Setup.withLocation testUrl
      )
      |> when "the batch command is triggered"
        [ Markup.target << by [ id "load-and-send" ]
        , Event.click
        ]
      |> it "changes the location" (
        Navigator.observe
          |> expect (Navigator.location <| equals "http://navigation-test-app.com/some-awesome-place")
      )
    )
  ]

type alias Model =
  ()

type Msg
  = ChangeLocation
  | ChangeOrigin
  | Reload
  | ReloadSkipCache
  | LoadAndSend
  | Ignore

testView : Model -> Html Msg
testView _ =
  Html.div []
  [ Html.button [ Attr.id "load-button", Events.onClick ChangeLocation ]
    [ Html.text "Click to change location!" ]
  , Html.button [ Attr.id "load-same-path-button", Events.onClick ChangeOrigin ]
    [ Html.text "Click to change location!" ]
  , Html.button [ Attr.id "reload-button", Events.onClick Reload ]
    [ Html.text "Click to reload!" ]
  , Html.button [ Attr.id "reload-skip-cache-button", Events.onClick ReloadSkipCache ]
    [ Html.text "Click to reload and skip cache!" ]
  , Html.button [ Attr.id "load-and-send", Events.onClick LoadAndSend ]
    [ Html.text "Click to load and send!" ]
  ]

testUpdate : Msg -> Model -> ( Model, Cmd Msg )
testUpdate msg model =
  case msg of
    ChangeLocation ->
      ( model
      , Browser.Navigation.load "/some-fun-place"
      )
    ChangeOrigin ->
      ( model
      , Browser.Navigation.load "http://some-other-spot.com"
      )
    Reload ->
      ( model
      , Browser.Navigation.reload
      )
    ReloadSkipCache ->
      ( model
      , Browser.Navigation.reloadAndSkipCache
      )
    LoadAndSend ->
      ( model
      , Cmd.batch
        [ Task.succeed never |> Task.perform (always Ignore)
        , Browser.Navigation.load "/some-awesome-place"
        ]
      )
    Ignore ->
      ( model, Cmd.none )


selectSpec : String -> Maybe (Spec Model Msg)
selectSpec name =
  case name of
    "loadUrl" -> Just loadUrlSpec
    "reload" -> Just reloadSpec
    "batchLoad" -> Just batchLoadSpec
    _ -> Nothing


main =
  Runner.browserProgram selectSpec