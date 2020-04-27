module Main exposing (..)

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Browser
import Browser.Events exposing (Visibility(..))
import Http
import Json.Decode as Json
import File exposing (File)
import File.Select
import Task


type Msg
  = ClickedButton
  | InputText String
  | VisibilityChange Visibility
  | WindowResize Int Int
  | SendRequest Bool
  | GotResponse (Result Http.Error String)
  | DocumentClick
  | OpenFileSelector
  | GotFile File
  | GotFileContents String


type alias Model =
  { count: Int
  , text: String
  , visibilityChanges: Int
  , sizes: List (Int, Int)
  , clicks: Int
  , uploadedFileContents: Maybe String
  }


defaultModel : Model
defaultModel =
  { count = 0
  , text = ""
  , visibilityChanges = 0
  , sizes = []
  , clicks = 0
  , uploadedFileContents = Nothing
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
  , Html.button [ Attr.id "open-file-selector", Events.onClick OpenFileSelector ] [ Html.text "Upload a file!" ]
  ]


filesDecoder : Json.Decoder (List File)
filesDecoder =
  Json.at [ "target", "files" ] (Json.list File.decoder)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    ClickedButton ->
      ( { model | count = model.count + 1 }, Cmd.none )
    InputText text ->
      ( { model | text = text }, Cmd.none )
    VisibilityChange visibility ->
      ( { model | visibilityChanges = model.visibilityChanges + 1 }, Cmd.none )
    SendRequest shouldSendRequest ->
      ( model
      , if shouldSendRequest then
          Http.get
            { url = "http://fun.com/fun"
            , expect = Http.expectString GotResponse
            }
        else
          Cmd.none
      )
    GotResponse _ ->
      ( model, Cmd.none )
    WindowResize width height ->
      ( { model | sizes = (width, height) :: model.sizes }, Cmd.none )
    DocumentClick ->
      ( { model | clicks = model.clicks + 1 }, Cmd.none )
    OpenFileSelector ->
      ( model, File.Select.file [] GotFile )
    GotFile file ->
      ( model, File.toString file |> Task.perform GotFileContents )
    GotFileContents contents ->
      ( { model | uploadedFileContents = Just contents }, Cmd.none )


init : () -> ( Model, Cmd Msg )
init _ =
  ( defaultModel, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.batch
  [ Browser.Events.onVisibilityChange VisibilityChange
  , Browser.Events.onVisibilityChange sendRequestWhenVisible
  , Browser.Events.onResize WindowResize
  , Browser.Events.onResize <| \_ _ -> SendRequest True
  , Browser.Events.onClick <| Json.succeed DocumentClick
  , Browser.Events.onClick <| Json.succeed <| SendRequest True
  ]


sendRequestWhenVisible : Visibility -> Msg
sendRequestWhenVisible visibility =
  case visibility of
    Visible ->
      SendRequest True
    Hidden ->
      SendRequest False


main =
  Browser.element
    { init = init
    , view = view
    , update = update
    , subscriptions = subscriptions
    }