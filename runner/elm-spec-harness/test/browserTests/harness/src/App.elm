module App exposing (..)

import Html exposing (Html)
import Html.Attributes as Attr


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
  Html.div []
    [ Html.h1 [ Attr.id "title" ] [ Html.text "Hey!" ]
    ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  ( model, Cmd.none )