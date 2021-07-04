module Specs.NoKeySpec exposing (..)

import Spec exposing (..)
import Spec.Setup as Setup
import Spec.Markup as Markup
import Spec.Markup.Selector exposing (..)
import Spec.Claim exposing (isSomethingWhere)
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Browser exposing (UrlRequest(..), Document)
import Browser.Navigation exposing (Key)
import Url exposing (Url)
import Url.Parser exposing ((</>))
import Url.Builder
import Specs.Helpers exposing (..)
import Runner as TestRunner


applicationSpec : Spec Model Msg
applicationSpec =
  Spec.describe "application"
  [ scenario "a url is provided" (
      given (
        Setup.initForApplication (testInit ())
          |> Setup.withDocument testDocument
          |> Setup.withUpdate testUpdate
          |> Setup.forNavigation { onUrlChange = UrlDidChange, onUrlRequest = UrlChangeRequested }
          |> Setup.withLocation (testUrl "/fun/reading")
      )
      |> observeThat
        [ it "renders the view based on the url" (
            Markup.observeElement
              |> Markup.query << by [ id "fun-page" ]
              |> expect (isSomethingWhere <| Markup.text <| equals "reading")
          )
        ]
    )
  ]


testUrl path =
  { protocol = Url.Http
  , host = "my-test-app.com"
  , port_ = Nothing
  , path = path
  , query = Nothing
  , fragment = Nothing
  }


testInit : () -> Url -> Key -> ( Model, Cmd Msg )
testInit _ initialUrl key =
  ( defaultModel initialUrl key, Cmd.none )


type alias Model =
  { key: Key
  , page: Page
  , title: String
  }


type Page
  = Home
  | Fun String


defaultModel : Url -> Key -> Model
defaultModel url key =
  { key = key
  , page = toPage url
  , title = "Some Boring Title"
  }


type Msg
  = Ignore
  | DoPushUrl
  | DoReplaceUrl
  | UrlDidChange Url
  | UrlChangeRequested UrlRequest
  | UpdateTitle


testUpdate : Msg -> Model -> ( Model, Cmd Msg )
testUpdate msg model =
  case msg of
    Ignore ->
      ( model, Cmd.none )
    UrlDidChange url ->
      ( { model | page = toPage url }, Cmd.none )
    UrlChangeRequested urlRequest ->
      case urlRequest of
        Internal url ->
          ( model, Browser.Navigation.pushUrl model.key <| Url.toString url )
        External url ->
          ( model, Browser.Navigation.load url )
    DoPushUrl ->
      ( model, Browser.Navigation.pushUrl model.key <| Url.Builder.absolute [ "fun", "bowling" ] [] )
    DoReplaceUrl ->
      ( model, Browser.Navigation.replaceUrl model.key <| Url.Builder.absolute [ "fun", "swimming" ] []  )
    UpdateTitle ->
      ( { model | title = "My Fun Title" }, Cmd.none )


toPage : Url -> Page
toPage url =
  case Url.Parser.parse (Url.Parser.s "fun" </> Url.Parser.string) url of
    Just sport ->
      Fun sport
    Nothing ->
      Home


testDocument : Model -> Document Msg
testDocument model =
  { title = model.title
  , body = [ testView model ]
  }


testView : Model -> Html Msg
testView model =
  case model.page of
    Home ->
      Html.div []
      [ Html.button [ Attr.id "push-url-button", Events.onClick DoPushUrl ] [ Html.text "Push!" ]
      , Html.button [ Attr.id "replace-url-button", Events.onClick DoReplaceUrl ] [ Html.text "Replace!" ]
      , Html.button [ Attr.id "update-title", Events.onClick UpdateTitle ] [ Html.text "Update title!" ]
      , Html.a [ Attr.id "internal-link", Attr.href "/fun/running" ] [ Html.text "Internal link!" ]
      , Html.a [ Attr.id "external-link", Attr.href "http://fun-town.org/fun" ] [ Html.text "External link!" ]
      ]
    Fun sport ->
      Html.div []
      [ Html.div [ Attr.id "fun-page" ]
        [ Html.text <| "Your favorite sport is: " ++ sport ]
      ]


main =
  Spec.program TestRunner.config
    [ applicationSpec
    ]