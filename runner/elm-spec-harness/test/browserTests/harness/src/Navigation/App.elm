port module Navigation.App exposing (..)

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Http
import Json.Decode as Json
import Url exposing (Url)
import Url.Parser as UrlParser exposing (Parser)
import Url.Builder
import Browser exposing (UrlRequest(..))
import Browser.Navigation as Navigation


type alias Model =
  { name: String
  , page: Page
  , key: Navigation.Key
  }


type Page
  = Home
  | Fun
  | Awesome
  | Super


defaultModel : Navigation.Key -> Page -> Model
defaultModel key page =
  { name = "Brian"
  , page = page
  , key = key
  }


type Msg
  = OnUrlChange Url
  | OnUrlRequest UrlRequest
  | NavigateToAwesome
  | SendToExternalLocation String


init : Url -> Navigation.Key -> ( Model, Cmd Msg )
init url key =
  let
    page =
      UrlParser.parse routes url
        |> Maybe.withDefault Home
  in
    ( defaultModel key page, Cmd.none )


routes =
  UrlParser.oneOf
    [ UrlParser.map Fun <| UrlParser.s "funPage"
    , UrlParser.map Awesome <| UrlParser.s "awesomePage"
    , UrlParser.map Super <| UrlParser.s "superPage"
    , UrlParser.map Home <| UrlParser.top
    ]


view : Model -> Html Msg
view model =
  case model.page of
    Home ->
      Html.div []
        [ Html.h1 [ Attr.id "title" ] [ Html.text <| "Hey " ++ model.name ++ "!" ]
        , Html.hr [] []
        , Html.div []
          [ Html.button [ Attr.id "awesome-location", Events.onClick NavigateToAwesome ] [ Html.text "Let's go!!!" ]
          ]
        , Html.hr [] []
        , Html.div []
          [ Html.a [ Attr.id "super-link", Attr.href "/superPage" ] [ Html.text "A Super Link" ]
          , Html.a [ Attr.id "external-link", Attr.href "http://fun-times.com/fun.html" ] [ Html.text "An External Link" ]
          ]
        ]
    Fun ->
      Html.div []
        [ Html.h1 [ Attr.id "title" ] [ Html.text "On the fun page!" ]
        ]
    Awesome ->
      Html.div []
        [ Html.h1 [ Attr.id "title" ] [ Html.text "On the awesome page!" ]
        ]
    Super ->
      Html.div []
        [ Html.h1 [ Attr.id "title" ] [ Html.text "On the super page!" ]
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    OnUrlChange url ->
      UrlParser.parse routes url
        |> Maybe.withDefault Home
        |> \page ->
          ( { model | page = page }, Cmd.none )
    OnUrlRequest urlRequest ->
      case urlRequest of
        Internal url ->
          ( model, Navigation.pushUrl model.key <| Url.toString url )
        External externalUrl ->
          ( model, Navigation.load externalUrl )
    NavigateToAwesome ->
      ( model, Navigation.pushUrl model.key <| Url.Builder.absolute [ "awesomePage" ] [] )
    SendToExternalLocation url ->
      ( model, Navigation.load url )


port triggerLocationChange : (String -> msg) -> Sub msg


subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.batch
  [ triggerLocationChange SendToExternalLocation
  ]