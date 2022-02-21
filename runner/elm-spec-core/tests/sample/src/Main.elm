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
import Bytes exposing (Bytes)
import Bytes.Decode as Bytes


type Msg
  = ClickedButton
  | InputText String
  | VisibilityChange Visibility
  | WindowResize Int Int
  | SendRequest Bool
  | GotTextResponse (Result Http.Error String)
  | DocumentClick
  | OpenFileSelector
  | GotFile File
  | GotFileContents String
  | DownloadText
  | DownloadBytes
  | GotBytesResponse (Result String Bytes)
  | GotProgress Http.Progress
  | GetMessages
  | GotMessages (Result Http.Error (List String))


type alias Model =
  { count: Int
  , text: String
  , visibilityChanges: Int
  , sizes: List (Int, Int)
  , clicks: Int
  , uploadedFileContents: Maybe String
  , downloadContents: Maybe String
  , progress: Maybe Http.Progress
  , messages: List String
  }


defaultModel : Model
defaultModel =
  { count = 0
  , text = ""
  , visibilityChanges = 0
  , sizes = []
  , clicks = 0
  , uploadedFileContents = Nothing
  , downloadContents = Nothing
  , progress = Nothing
  , messages = []
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
  , Html.button [ Attr.id "download-text", Events.onClick DownloadText ] [ Html.text "Download text" ]
  , Html.button [ Attr.id "download-bytes", Events.onClick DownloadBytes ] [ Html.text "Download bytes" ]
  , Html.div [ Attr.id "download-progress" ]
    [ Maybe.map getProgress model.progress
        |> Maybe.withDefault "No request"
        |> Html.text
    ]
  , Html.button [ Attr.id "get-messages", Events.onClick GetMessages ] [ Html.text "Get Messages" ]
  , Html.div [ Attr.id "some-styled-element" ] [ Html.text "Some styled text!" ]
  ]


getProgress : Http.Progress -> String
getProgress progress =
  case progress of
    Http.Sending _ ->
      "Sending ..."
    Http.Receiving details ->
      let
        fraction =
          Http.fractionReceived details * 100
            |> round
            |> String.fromInt
      in
        "Downloaded " ++ fraction ++ "%"


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
            , expect = Http.expectString GotTextResponse
            }
        else
          Cmd.none
      )
    GotTextResponse result ->
      case result of
        Ok content ->
          ( { model | downloadContents = Just content }, Cmd.none )
        Err _ ->
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
    DownloadText ->
      ( model
      , Http.request
        { method = "GET"
        , headers = []
        , url = "http://fake-fun.com/api/files/21"
        , body = Http.emptyBody
        , expect = Http.expectString GotTextResponse
        , timeout = Nothing
        , tracker = Just "download"
        }
      )
    DownloadBytes ->
      ( model
      , Http.request
        { method = "GET"
        , headers = []
        , url = "http://fake-fun.com/api/files/21"
        , body = Http.emptyBody
        , expect = Http.expectBytesResponse GotBytesResponse handleBytesResponse
        , timeout = Nothing
        , tracker = Just "download"
        }
      )
    GotBytesResponse response ->
      case response of
        Ok bytes ->
          case Bytes.decode (Bytes.string <| Bytes.width bytes) bytes of
            Just text ->
              ( { model | downloadContents = Just text }, Cmd.none )
            Nothing ->
              ( { model | downloadContents = Nothing }, Cmd.none )
        Err _ ->
          ( model, Cmd.none )
    GotProgress progress ->
      ( { model | progress = Just progress }, Cmd.none )
    GetMessages ->
      ( model
      , Http.get
        { url = "http://fake-fun.com/api/messages"
        , expect = Http.expectJson GotMessages (Json.list <| Json.field "text" Json.string)
        }
      )
    GotMessages result ->
      case result of
        Ok texts ->
          ( { model | messages = texts }, Cmd.none )
        Err _ ->
          ( { model | messages = [] }, Cmd.none )


handleBytesResponse : Http.Response Bytes -> Result String Bytes
handleBytesResponse response =
  case response of
    Http.GoodStatus_ metadata bytes ->
      Ok bytes
    _ ->
      Err "Something not good happened!"


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
  , Http.track "download" GotProgress
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