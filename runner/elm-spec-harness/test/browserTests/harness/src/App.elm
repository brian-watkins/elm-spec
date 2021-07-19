module App exposing (..)

import Html exposing (Html)


type alias Model =
  { name: String
  , attributes: List String
  }


defaultModel : Model
defaultModel =
  { name = "Brian"
  , attributes = [ "cool", "fun" ]
  }


type Msg
  = Msg


view : Model -> Html Msg
view model =
  Html.h1 []
    [ Html.text "Hey!"]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  ( model, Cmd.none )