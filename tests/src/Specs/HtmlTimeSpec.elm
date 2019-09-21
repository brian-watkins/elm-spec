port module Specs.HtmlTimeSpec exposing (..)

import Spec exposing (Spec)
import Spec.Subject as Subject
import Spec.Scenario exposing (..)
import Spec.Html as Markup exposing (hasText)
import Spec.Html.Selector exposing (..)
import Spec.Time
import Html exposing (Html)
import Html.Attributes as Attr
import Runner
import Time exposing (Posix)


intervalSpec : Spec Model Msg
intervalSpec =
  Spec.describe "an Html program that updates the time"
  [ scenario "the expected amount of time passes" (
      Subject.initWithModel { count = 0 }
        |> Subject.withUpdate testUpdate
        |> Subject.withView testView
        |> Subject.withSubscriptions testSubscriptions
        |> Spec.Time.fake
    )
    |> when "time passes"
      [ Spec.Time.tick 1000
      , Spec.Time.tick 1000
      , Spec.Time.tick 1000
      , Spec.Time.tick 1000
      ]
    |> it "updates the count" (
      select << by [ id "seconds-passed" ]
        |> Markup.expectElement (hasText "4 seconds passed")
    )
  ]


type Msg
  = TimeUpdate Posix


type alias Model =
  { count: Int
  }


testUpdate : Msg -> Model -> ( Model, Cmd Msg )
testUpdate msg model =
  case msg of
    TimeUpdate _ ->
      ( { model | count = model.count + 1 }, Cmd.none )


testView : Model -> Html Msg
testView model =
  Html.div []
  [ Html.div [ Attr.id "seconds-passed" ] [ Html.text <| String.fromInt model.count ++ " seconds passed"]
  ]


testSubscriptions : Model -> Sub Msg
testSubscriptions _ =
  Time.every 1000 TimeUpdate 


selectSpec : String -> Maybe (Spec Model Msg)
selectSpec name =
  case name of
    "interval" -> Just intervalSpec
    _ -> Nothing


main =
  Runner.browserProgram selectSpec