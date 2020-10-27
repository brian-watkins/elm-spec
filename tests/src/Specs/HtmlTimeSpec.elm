module Specs.HtmlTimeSpec exposing (..)

import Spec exposing (..)
import Spec.Setup as Setup
import Spec.Markup as Markup
import Spec.Markup.Selector exposing (..)
import Spec.Markup.Event as Event
import Spec.Observer as Observer
import Spec.Time
import Spec.Claim exposing (isSomethingWhere)
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Runner
import Specs.Helpers exposing (..)
import Time exposing (Posix)
import Task


stubSpec : Spec Model Msg
stubSpec =
  Spec.describe "an Html program that stubs the time"
  [ scenario "the time is stubbed" (
      given (
        Setup.initWithModel testModel
          |> Setup.withUpdate testUpdate
          |> Setup.withView testView
          |> Spec.Time.withTime 1515281017615
      )
      |> when "the time is requested"
        [ Markup.target << by [ id "get-time" ]
        , Event.click
        ]
      |> it "displays the current time" (
        Markup.observeElement
          |> Markup.query << by [ id "current-time" ]
          |> expect (isSomethingWhere <| Markup.text <| equals "1515281017632")
      )
    )
  ]


intervalSpec : Spec Model Msg
intervalSpec =
  Spec.describe "an Html program that updates the time"
  [ scenario "the expected amount of time passes" (
      given (
        Setup.initWithModel testModel
          |> Setup.withUpdate testUpdate
          |> Setup.withView testView
          |> Setup.withSubscriptions testSubscriptions
      )
      |> when "time passes"
        [ Spec.Time.tick 1000
        , Spec.Time.tick 1000
        , Spec.Time.tick 1000
        , Spec.Time.tick 1000
        ]
      |> it "updates the count" (
        Markup.observeElement
          |> Markup.query << by [ id "seconds-passed" ]
          |> expect (isSomethingWhere <| Markup.text <| equals "4 seconds passed")
      )
    )
  ]


type Msg
  = TimeUpdate Posix
  | GetTime


type alias Model =
  { count: Int
  , time: Posix
  }


testModel =
  { count = 0
  , time = Time.millisToPosix 0
  }


testUpdate : Msg -> Model -> ( Model, Cmd Msg )
testUpdate msg model =
  case msg of
    TimeUpdate time ->
      ( { model | time = time, count = model.count + 1 }, Cmd.none )
    GetTime ->
      ( model, Time.now |> Task.perform TimeUpdate )


testView : Model -> Html Msg
testView model =
  Html.div []
  [ Html.div [ Attr.id "seconds-passed" ] [ Html.text <| String.fromInt model.count ++ " seconds passed"]
  , Html.div [ Attr.id "current-time" ] [ Html.text <| String.fromInt <| Time.posixToMillis model.time ]
  , Html.button [ Attr.id "get-time", Events.onClick GetTime ] [ Html.text "Click me" ]
  ]


testSubscriptions : Model -> Sub Msg
testSubscriptions _ =
  Time.every 1000 TimeUpdate 


selectSpec : String -> Maybe (Spec Model Msg)
selectSpec name =
  case name of
    "interval" -> Just intervalSpec
    "stub" -> Just stubSpec
    _ -> Nothing


main =
  Runner.browserProgram selectSpec