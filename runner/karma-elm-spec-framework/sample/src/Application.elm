module Application exposing (..)

import Browser exposing (Document)
import Browser.Navigation exposing (Key)
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Url exposing (Url)
import Url.Parser exposing ((</>))
import Url.Builder


type alias Model =
  { key: Key
  , page: Page
  }


type Page
  = Home
  | Fun String


defaultModel : Key -> Model
defaultModel key =
  { key = key
  , page = Home
  }


type Msg
  = Ignore
  | DoPushUrl
  | UrlDidChange Url


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    Ignore ->
      ( model, Cmd.none )
    UrlDidChange url ->
      ( { model | page = toPage url }, Cmd.none )
    DoPushUrl ->
      ( model, Browser.Navigation.pushUrl model.key <| Url.Builder.absolute [ "fun", "bowling" ] [] )


toPage : Url -> Page
toPage url =
  case Url.Parser.parse (Url.Parser.s "fun" </> Url.Parser.string) url of
    Just sport ->
      Fun sport
    Nothing ->
      Home


document : Model -> Document Msg
document model =
  { title = "Fun Stuff"
  , body = [ view model ]
  }


view : Model -> Html Msg
view model =
  case model.page of
    Home ->
      Html.div []
      [ Html.button [ Attr.id "push-url-button", Events.onClick DoPushUrl ] [ Html.text "Push!" ]
      ]
    Fun sport ->
      Html.div []
      [ Html.div [ Attr.id "fun-page" ]
        [ Html.text <| "Your favorite sport is: " ++ sport ]
      ]


init : () -> Url -> Key -> ( Model, Cmd Msg )
init _ _ key =
  ( defaultModel key, Cmd.none )

onUrlRequest _ =
  Ignore

main =
  Browser.application
    { init = init
    , view = document
    , update = update
    , subscriptions = \_ -> Sub.none
    , onUrlRequest = onUrlRequest
    , onUrlChange = UrlDidChange
    }