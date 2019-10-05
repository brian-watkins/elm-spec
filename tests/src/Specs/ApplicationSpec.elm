module Specs.ApplicationSpec exposing (..)

import Spec exposing (Spec)
import Spec.Subject as Subject
import Spec.Scenario exposing (..)
import Spec.Markup as Markup
import Spec.Markup.Selector exposing (..)
import Spec.Markup.Event as Event
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Browser exposing (UrlRequest)
import Browser.Navigation exposing (Key)
import Runner
import Url exposing (Url)
import Url.Parser exposing ((</>))
import Url.Builder


noChangeHandlerSpec : Spec Model Msg
noChangeHandlerSpec =
  Spec.describe "on url change"
  [ scenario "no url change handler is set" (
      Subject.initWithKey (testInit () testUrl)
        |> Subject.withView testView
        |> Subject.withUpdate testUpdate
    )
    |> when "the url is changed"
      [ target << by [ id "push-url-button" ]
      , Event.click
      ]
    |> it "fails" (
      select << by [ id "no-page" ]
        |> Markup.expectElement ( Markup.hasText "bowling" )
    )
  ]


changeUrlSpec : Spec Model Msg
changeUrlSpec =
  Spec.describe "on url change"
  [ scenario "before pushUrl is used" (
      testSubject
    )
    |> it "does not show anything fun" (
      select << by [ id "fun-page" ]
        |> Markup.expectAbsent
    )
  , scenario "use pushUrl to navigate" (
      testSubject
    )
    |> when "the url is changed"
      [ target << by [ id "push-url-button" ]
      , Event.click
      ]
    |> it "shows a different page" (
      select << by [ id "fun-page" ]
        |> Markup.expectElement ( Markup.hasText "bowling" )
    )
  , scenario "use replaceUrl to navigate" (
      testSubject
    )
    |> when "the url is changed"
      [ target << by [ id "replace-url-button" ]
      , Event.click
      ]
    |> it "shows a different page" (
      select << by [ id "fun-page" ]
        |> Markup.expectElement ( Markup.hasText "swimming" )
    )
  ]

testSubject =
  Subject.initWithKey (testInit () testUrl)
    |> Subject.withView testView
    |> Subject.withUpdate testUpdate
    |> Subject.onUrlChange testOnUrlChange


testOnUrlChange : Url -> Msg
testOnUrlChange =
  UrlDidChange


testUrl =
  { protocol = Url.Http
  , host = "test-app.com"
  , port_ = Nothing
  , path = "/"
  , query = Nothing
  , fragment = Nothing
  }


testInit : () -> Url -> Key -> ( Model, Cmd Msg )
testInit _ initialUrl key =
  ( defaultModel key, Cmd.none )


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
  | DoReplaceUrl
  | UrlDidChange Url


testUpdate : Msg -> Model -> ( Model, Cmd Msg )
testUpdate msg model =
  case msg of
    Ignore ->
      ( model, Cmd.none )
    UrlDidChange url ->
      ( { model | page = toPage url }, Cmd.none )
    DoPushUrl ->
      ( model, Browser.Navigation.pushUrl model.key <| Url.Builder.absolute [ "fun", "bowling" ] [] )
    DoReplaceUrl ->
      ( model, Browser.Navigation.replaceUrl model.key <| Url.Builder.absolute [ "fun", "swimming" ] []  )


toPage : Url -> Page
toPage url =
  case Url.Parser.parse (Url.Parser.s "fun" </> Url.Parser.string) url of
    Just sport ->
      Fun sport
    Nothing ->
      Home


testView : Model -> Html Msg
testView model =
  case model.page of
    Home ->
      Html.div []
      [ Html.button [ Attr.id "push-url-button", Events.onClick DoPushUrl ] [ Html.text "Push!" ]
      , Html.button [ Attr.id "replace-url-button", Events.onClick DoReplaceUrl ] [ Html.text "Replace!" ]
      ]
    Fun sport ->
      Html.div []
      [ Html.div [ Attr.id "fun-page" ]
        [ Html.text <| "Your favorite sport is: " ++ sport ]
      ]


selectSpec : String -> Maybe (Spec Model Msg)
selectSpec name =
  case name of
    "changeUrl" -> Just changeUrlSpec
    "noChangeUrlHandler" -> Just noChangeHandlerSpec
    _ -> Nothing


main =
  Runner.browserApplication selectSpec