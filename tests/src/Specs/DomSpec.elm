module Specs.DomSpec exposing (main)

import Spec exposing (..)
import Spec.Setup as Setup
import Spec.Claim as Claim exposing (..)
import Spec.Markup as Markup
import Spec.Markup.Event as Event
import Spec.Markup.Selector exposing (..)
import Spec.Observer as Observer
import Specs.Helpers exposing (..)
import Specs.EventHelpers
import Spec.Command as Command
import Runner
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Task
import Browser.Dom
import Json.Decode as Json


viewportSpec : Spec Model Msg
viewportSpec =
  Spec.describe "viewport"
  [ scenario "the viewport position is updated" (
      given (
        testSubject
      )
      |> when "the viewport is updated"
        [ Markup.target << by [ id "x-position" ]
        , Event.input "50"
        , Markup.target << by [ id "y-position" ]
        , Event.input "20"
        , Markup.target << by [ id "set-viewport-button" ]
        , Event.click
        ]
      |> when "the viewport is requested"
        [ Markup.target << by [ id "request-viewport-button" ]
        , Event.click
        ]
      |> it "recognizes that the viewport has been updated" (
        Observer.observeModel .viewport
          |> expect (equals { x = 50, y = 20 })
      )
    )
  , scenario "update viewport position via command.send" (
      given (
        testSubject
      )
      |> when "the viewport is updated"
        [ Markup.target << by [ id "x-position" ]
        , Event.input "70"
        , Markup.target << by [ id "y-position" ]
        , Event.input "30"
        , Markup.target << by [ id "set-viewport-button" ]
        , Event.click
        ]
      |> when "the command to request the viewport is sent as a step"
        [ Command.send <| getViewport GotViewport
        ]
      |> it "recognizes that the viewport has been updated" (
        Observer.observeModel .viewport
          |> expect (equals { x = 70, y = 30 })
      )
    )
  ]


observeBrowserViewportSpec : Spec Model Msg
observeBrowserViewportSpec =
  Spec.describe "observeBrowserViewport"
  [ scenario "the viewport has not been changed" (
      given (
        testSubject
      )
      |> it "observes that the viewport is offset at (0, 0)" (
        Markup.observeBrowserViewport
          |> expect (equals { x = 0, y = 0 })
      )
    )
  , scenario "the viewport has been set" (
      given (
        testSubject
      )
      |> when "the viewport position is set"
        [ Event.setBrowserViewport { x = 81, y = 9.7 }
        ]
      |> it "observes that the viewport is offset at the expected position" (
        Markup.observeBrowserViewport
          |> expect (equals { x = 81, y = 9.7 })
      )
    )
  , scenario "the viewport is observed in another scenario" (
      given (
        testSubject
      )
      |> it "observes that the viewport is reset to (0, 0)" (
        Markup.observeBrowserViewport
          |> expect (equals { x = 0, y = 0 })
      )
    )
  ]


setElementViewportSpec : Spec Model Msg
setElementViewportSpec =
  Spec.describe "setElementViewport"
  [ scenario "success" (
      given (
        testSubject
      )
      |> when "the element is scrolled"
        [ Markup.target << by [ id "scrollable-element" ]
        , Event.setElementViewport { x = 19, y = 200 }
        ]
      |> it "adjusts the element viewport" (
        Markup.observeElement
          |> Markup.query << by [ id "scrollable-element" ]
          |> expect (isSomethingWhere <| satisfying
            [ Markup.property (Json.field "scrollTop" Json.float) <| equals 200
            , Markup.property (Json.field "scrollLeft" Json.float) <| equals 19
            ]
          )
      )
    )
  , eventStepFailsWhenNoElementTargeted <| Event.setElementViewport { x = 19, y = 200 }
  , eventStepFailsWhenDocumentTargeted <| Event.setElementViewport { x = 19, y = 200 }
  ]


eventStepFailsWhenNoElementTargeted =
  Specs.EventHelpers.eventStepFailsWhenNoElementTargeted testSubject


eventStepFailsWhenDocumentTargeted =
  Specs.EventHelpers.eventStepFailsWhenDocumentTargeted testSubject


type alias Model =
  { viewport: { x: Float, y: Float }
  , scrollTo: { x: Float, y: Float }
  }


type Msg
  = RequestViewport
  | GotViewport { x: Float, y: Float }
  | GotX String
  | GotY String
  | SetViewport
  | DidSetViewport ()


testSubject =
  Setup.initWithModel { viewport = { x = 0, y = 0 }, scrollTo = { x = 0, y = 0 } }
    |> Setup.withView testView
    |> Setup.withUpdate testUpdate


testView : Model -> Html Msg
testView model =
  Html.div []
  [ Html.input [ Attr.id "x-position", Events.onInput GotX ] []
  , Html.input [ Attr.id "y-position", Events.onInput GotY ] []
  , Html.button [ Attr.id "set-viewport-button", Events.onClick SetViewport ] [ Html.text "Set!" ]
  , Html.button [ Attr.id "request-viewport-button", Events.onClick RequestViewport ] [ Html.text "Get!"]
  , Html.hr [] []
  , Html.div
    [ Attr.id "scrollable-element"
    , Attr.style "width" "300px"
    , Attr.style "height" "200px"
    , Attr.style "overflow" "hidden"
    ]
    [ Html.div
      [ Attr.id "element-with-large-content"
      , Attr.style "width" "500px"
      , Attr.style "height" "1000px"
      ] [ Html.text "Lots of content!" ]
    ]
  ]


testUpdate : Msg -> Model -> (Model, Cmd Msg)
testUpdate msg model =
  case msg of
    GotX x ->
      ( { model
        | scrollTo =
          { x = String.toFloat x |> Maybe.withDefault 0.0
          , y = model.scrollTo.y 
          }
        }
      , Cmd.none
      )
    GotY y ->
        ( { model
        | scrollTo =
          { x = model.scrollTo.x
          , y = String.toFloat y |> Maybe.withDefault 0.0
          }
        }
      , Cmd.none
      )
    SetViewport ->
      ( model
      , Browser.Dom.setViewport model.scrollTo.x model.scrollTo.y |> Task.perform DidSetViewport
      )
    DidSetViewport _ ->
      ( model, Cmd.none )
    RequestViewport ->
      ( model, getViewport GotViewport )
    GotViewport viewport ->
      ( { model | viewport = viewport }, Cmd.none )


getViewport tagger =
  Browser.Dom.getViewport
    |> Task.map .viewport
    |> Task.map (\v -> { x = v.x, y = v.y })
    |> Task.perform tagger


selectSpec : String -> Maybe (Spec Model Msg)
selectSpec name =
  case name of
    "viewport" -> Just viewportSpec
    "observeBrowserViewport" -> Just observeBrowserViewportSpec
    "setElementViewport" -> Just setElementViewportSpec
    _ -> Nothing


main =
  Runner.browserProgram selectSpec