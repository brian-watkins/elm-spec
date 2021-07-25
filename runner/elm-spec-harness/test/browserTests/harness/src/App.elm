port module App exposing (..)

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events


type alias Model =
  { name: String
  , attributes: List String
  , clicks: Int
  }


defaultModel : Model
defaultModel =
  { name = "Brian"
  , attributes = [ "cool", "fun" ]
  , clicks = 0
  }


type Msg
  = CounterClicked
  | InformClicked
  | Triggered TriggerMessage


view : Model -> Html Msg
view model =
  Html.div []
    [ Html.h1 [ Attr.id "title" ] [ Html.text <| "Hey " ++ model.name ++ "!" ]
    , Html.button [ Attr.id "counter-button", Events.onClick CounterClicked ] [ Html.text "Click me!" ]
    , Html.h3 [ Attr.id "counter-status" ] [ Html.text <| String.fromInt model.clicks ++ " clicks!" ]
    , Html.hr [] []
    , Html.div []
      [ Html.button [ Attr.id "inform-button", Events.onClick InformClicked ] [ Html.text "Inform!" ]
      ]
    ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    CounterClicked ->
      ( { model | clicks = model.clicks + 1 }, Cmd.none )
    Triggered message ->
      ( { model | name = message.name }, Cmd.none )
    InformClicked ->
      ( model, inform { attributes = "awesome" :: model.attributes } )


type alias TriggerMessage =
  { name: String
  }


port triggerStuff : (TriggerMessage -> msg) -> Sub msg
port inform : { attributes: List String } -> Cmd msg

subscriptions : Model -> Sub Msg
subscriptions model =
  triggerStuff Triggered