module Main exposing (..)

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Browser


type Msg
  = ClickedButton
  | InputText String


type alias Model =
  { count: Int
  , text: String
  }


defaultModel : Model
defaultModel =
  { count = 0
  , text = ""
  }


view : Model -> Html Msg
view model =
  Html.div []
  [ Html.h2 [] [ Html.text "Welcome to this cool web application!" ]
  , Html.button [ Attr.id "my-button", Events.onClick ClickedButton ] [ Html.text "Click Me!" ]
  , Html.div [ Attr.id "count-results" ] 
      [ Html.text <| "You clicked the button " ++ String.fromInt model.count ++ " time(s)" ]
  , Html.hr [] []
  , Html.input [ Attr.id "my-input", Events.onInput InputText ] []
  , Html.div [ Attr.id "input-results" ]
      [ Html.text <| "You typed: " ++ model.text ]
  ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    ClickedButton ->
      ( { model | count = model.count + 1 }, Cmd.none )
    InputText text ->
      ( { model | text = text }, Cmd.none )


init : () -> ( Model, Cmd Msg )
init _ =
  ( defaultModel, Cmd.none )


main =
  Browser.element
    { init = init
    , view = view
    , update = update
    , subscriptions = \_ -> Sub.none
    }