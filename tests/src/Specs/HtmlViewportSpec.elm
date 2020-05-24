module Specs.HtmlViewportSpec exposing (main)

import Spec exposing (..)
import Spec.Setup as Setup
import Spec.Claim as Claim exposing (..)
import Spec.Markup as Markup
import Spec.Markup.Event as Event
import Spec.Markup.Selector exposing (..)
import Spec.Navigator as Navigator
import Spec.Observer as Observer
import Spec.Witness as Witness
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
import Json.Encode as Encode


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
        Navigator.observe
          |> expect (Navigator.viewportOffset <| equals { x = 0, y = 0})
      )
    )
  , scenario "the viewport is set in a batch with a command the stores an effect message and nothing triggers an extra animation frame update" (
      given (
        testSubject
      )
      |> when "the viewport is updated"
        [ Markup.target << by [ id "x-position" ]
        , Event.input "58"
        , Markup.target << by [ id "y-position" ]
        , Event.input "21"
        , Markup.target << by [ id "set-viewport-with-witness" ]
        , Event.click
        ]
      |> observeThat
        [ it "records the witness message" (
            Witness.observe "fun-message" Json.string
              |> expect (isListWhere
                [ equals "a fun recorded message"
                ]
              )
          )
        ]
    )
  , scenario "the viewport has been set" (
      given (
        testSubject
      )
      |> when "the viewport position is set"
        [ Navigator.setViewportOffset { x = 81, y = 9.7 }
        ]
      |> it "observes that the viewport is offset at the expected position" (
        Navigator.observe
          |> expect (Navigator.viewportOffset <| equals { x = 81, y = 9.7 })
      )
    )
  , scenario "the viewport is observed in another scenario" (
      given (
        testSubject
      )
      |> it "observes that the viewport is reset to (0, 0)" (
        Navigator.observe
          |> expect (Navigator.viewportOffset <| equals { x = 0, y = 0 })
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
        , Event.setViewportOffset { x = 19, y = 200 }
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
  , eventStepFailsWhenNoElementTargeted <| Event.setViewportOffset { x = 19, y = 200 }
  , eventStepFailsWhenDocumentTargeted <| Event.setViewportOffset { x = 19, y = 200 }
  ]


eventStepFailsWhenNoElementTargeted =
  Specs.EventHelpers.eventStepFailsWhenNoElementTargeted testSubject


eventStepFailsWhenDocumentTargeted =
  Specs.EventHelpers.eventStepFailsWhenDocumentTargeted testSubject


elementPositionSpec : Spec Model Msg
elementPositionSpec =
  Spec.describe "element position as the broswer viewport changes"
  [ scenario "initial browser viewport" (
      given (
        testSubject
      )
      |> whenTheElementIsRequested
      |> observeThat
        [ itObservesXPositionToBe 0
        , itObservesYPositionToBe 239
        ]
    )
  , scenario "the browser viewport moves" (
      given (
        testSubject
      )
      |> when "the browser viewport moves"
        [ Navigator.setViewportOffset { x = 30, y = 94 }
        ]
      |> whenTheElementIsRequested
      |> observeThat
        [ itObservesXPositionToBe 0
        , itObservesYPositionToBe 239
        ]
    )
  , scenario "an element is not found" (
      given (
        testSubject
      )
      |> when "an element is not found"
        [ Command.send <| Command.fake <| RequestElement "some-unknown-element"
        ]
      |> it "does not find an element" (
        Observer.observeModel .element
          |> expect isNothing
      )
    )
  ]


jsdomElementSpec : Spec Model Msg
jsdomElementSpec =
  Spec.describe "jsdom element"
  [ scenario "get an element" (
      given (
        testSubject
      )
      |> whenTheElementIsRequested
      |> observeThat
        [ itObservesXPositionToBe 0
        , itObservesYPositionToBe 0
        ]
    )
  ]


whenTheElementIsRequested =
  when "the element is requested"
    [ Markup.target << by [ id "get-footer-button" ]
    , Event.click
    ]


itObservesXPositionToBe expected =
  it "finds the x position of the element" (
    Observer.observeModel .element
      |> expect (isSomethingWhere <| specifyThat .element <| specifyThat .x <| equals expected)
  )


itObservesYPositionToBe expected =
  it "finds the y position of the element" (
    Observer.observeModel .element
      |> expect (isSomethingWhere <| specifyThat .element <| specifyThat .y <| equals expected)
  )


type alias Model =
  { viewport: { x: Float, y: Float }
  , scrollTo: { x: Float, y: Float }
  , element: Maybe Browser.Dom.Element
  }


defaultModel =
  { viewport = { x = 0, y = 0 }
  , scrollTo = { x = 0, y = 0 }
  , element = Nothing
  }


type Msg
  = RequestViewport
  | GotViewport { x: Float, y: Float }
  | GotX String
  | GotY String
  | SetViewport
  | SetViewportWithWitness
  | DidSetViewport ()
  | RequestElement String
  | GotElement (Result Browser.Dom.Error Browser.Dom.Element)


testSubject =
  Setup.initWithModel defaultModel
    |> Setup.withView testView
    |> Setup.withUpdate testUpdate


testView : Model -> Html Msg
testView model =
  Html.div []
  [ Html.input [ Attr.id "x-position", Events.onInput GotX ] []
  , Html.input [ Attr.id "y-position", Events.onInput GotY ] []
  , Html.button [ Attr.id "set-viewport-button", Events.onClick SetViewport ] [ Html.text "Set!" ]
  , Html.button [ Attr.id "set-viewport-with-witness", Events.onClick SetViewportWithWitness ] [ Html.text "Set with witness!" ]
  , Html.button [ Attr.id "request-viewport-button", Events.onClick RequestViewport ] [ Html.text "Get!"]
  , Html.button [ Attr.id "get-footer-button", Events.onClick <| RequestElement "footer" ] [ Html.text "Get Footer!" ]
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
  , Html.div [ Attr.id "footer" ] [ Html.text "This is the footer element!" ]
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
    SetViewportWithWitness ->
      ( model
      , Cmd.batch
        [ Browser.Dom.setViewport model.scrollTo.x model.scrollTo.y |> Task.perform DidSetViewport
        , recordWitness "fun-message" <| Encode.string "a fun recorded message"
        ]
      )
    DidSetViewport _ ->
      ( model, Cmd.none )
    RequestViewport ->
      ( model, getViewport GotViewport )
    GotViewport viewport ->
      ( { model | viewport = viewport }, Cmd.none )
    RequestElement elementId ->
      ( model, Browser.Dom.getElement elementId |> Task.attempt GotElement )
    GotElement elementResult ->
      case elementResult of
        Ok element ->
          ( { model | element = Just element }, Cmd.none )
        Err _ ->
          ( { model | element = Nothing }, Cmd.none )


recordWitness =
  Witness.connect Runner.elmSpecOut
    |> Witness.record


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
    "elementPosition" -> Just elementPositionSpec
    "jsdomElement" -> Just jsdomElementSpec
    _ -> Nothing


main =
  Runner.browserProgram selectSpec