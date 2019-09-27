module Specs.NavigationSpec exposing (main)

import Spec exposing (Spec)
import Spec.Subject as Subject
import Spec.Scenario exposing (..)
import Spec.Markup as Markup
import Spec.Markup.Navigation as Navigation
import Spec.Observation as Observation
import Spec.Observer exposing (..)
import Spec.Markup.Selector exposing (..)
import Spec.Markup.Event as Event
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Browser.Navigation
import Runner


loadUrlSpec : Spec Model Msg
loadUrlSpec =
  Spec.describe "a program that uses Browser.Navigation.loadUrl"
  [ scenario "a new URL is loaded" (
      Subject.initWithModel ()
        |> Subject.withView testView
        |> Subject.withUpdate testUpdate
    )
    |> when "a new page load is triggered"
      [ target << by [ id "load-button" ]
      , Event.click
      ]
    |> it "updates the document location" (
      Navigation.selectLocation
        |> Observation.expect (isEqual "/some-fun-place")
    )
  ]


type alias Model =
  ()

type Msg
  = ChangeLocation

testView : Model -> Html Msg
testView model =
  Html.div []
  [ Html.button [ Attr.id "load-button", Events.onClick ChangeLocation ]
    [ Html.text "Click to change location!" ]
  ]

testUpdate : Msg -> Model -> ( Model, Cmd Msg )
testUpdate msg model =
  case msg of
    ChangeLocation ->
      ( model
      , Browser.Navigation.load "/some-fun-place"
      )

selectSpec : String -> Maybe (Spec Model Msg)
selectSpec name =
  case name of
    "loadUrl" -> Just loadUrlSpec
    _ -> Nothing


main =
  Runner.browserProgram selectSpec