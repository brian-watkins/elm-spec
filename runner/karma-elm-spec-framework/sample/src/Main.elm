module Main exposing (..)

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Browser
import Http
import Json.Decode as Json


type Msg
  = ClickedButton
  | SendRequest
  | InputText String
  | ReceivedResponse (Result Http.Error String)


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
  , Html.button [ Attr.id "request-button", Events.onClick SendRequest ] [ Html.text "Make a request!" ]
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
    SendRequest ->
      ( model
      , getRequest
      )
    ReceivedResponse _ ->
      ( model, Cmd.none )


getRequest : Cmd Msg
getRequest =
  Http.request
    { method = "GET"
    , headers =
      [ Http.header "X-Fun-Header" "some-fun-value"
      , Http.header "X-Awesome-Header" "some-awesome-value"
      ]
    , url = "http://fake-api.com/stuff"
    , body = Http.emptyBody
    , expect = Http.expectJson ReceivedResponse <| Json.succeed "HEY!"
    , timeout = Nothing
    , tracker = Nothing
    }


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