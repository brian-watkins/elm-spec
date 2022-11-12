module WithLogs.DebugSpec exposing (..)

import Spec exposing (..)
import Spec.Setup as Setup
import Spec.Markup as Markup
import Spec.Markup.Selector exposing (..)
import Spec.Markup.Event as Event
import Spec.Claim exposing (isStringContaining, isSomethingWhere)
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Runner


debugSpec : Spec Model Msg
debugSpec =
  describe "debug message"
  [ scenario "there is a debug message" (
      given (
        Setup.initWithModel defaultModel
          |> Setup.withUpdate update
          |> Setup.withView view
      )
      |> when "a click occurs"
        [ Markup.target << by [ tag "button" ]
        , Event.click
        ]
      |> it "updates the count" (
        Markup.observeElement
          |> Markup.query << by [ id "counter-text" ]
          |> expect (isSomethingWhere <| Markup.text <| isStringContaining 1 "Click count: 1")
      )
    )
  ]


type Msg
  = HandleClick


type alias Model =
  { count: Int
  }


defaultModel : Model
defaultModel =
  { count = 0
  }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  let
    d = Debug.log "UPDATE" msg
  in
    case msg of
      HandleClick ->
        ( { model | count = model.count + 1 }, Cmd.none )


view : Model -> Html Msg
view model =
  Html.div []
  [ Html.button
    [ Events.onClick HandleClick ]
    [ Html.text "Click ms!" ]
  , Html.div [ Attr.id "counter-text" ]
    [ Html.text <| "Click count: " ++ String.fromInt model.count ]
  ]


main =
  Runner.program
    [ debugSpec
    ]
