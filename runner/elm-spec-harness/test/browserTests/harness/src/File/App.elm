module File.App exposing (..)

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Json.Decode as Json
import File exposing (File)


type Model
  = Model


defaultModel : Model
defaultModel =
  Model


type Msg
  = GotFiles (List File)


view : Model -> Html Msg
view _ =
  Html.div []
  [ Html.input 
    [ Attr.type_ "file"
    , Events.on "change" (Json.map GotFiles filesDecoder)
    ] []
  ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  ( model, Cmd.none )


filesDecoder : Json.Decoder (List File)
filesDecoder =
  Json.at [ "target", "files" ] (Json.list File.decoder)
