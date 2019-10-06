module Specs.ApplicationSpec exposing (..)

import Spec exposing (Spec)
import Spec.Subject as Subject
import Spec.Scenario exposing (..)
import Spec.Markup as Markup
import Spec.Markup.Selector exposing (..)
import Spec.Markup.Event as Event
import Spec.Markup.Navigation as Navigation
import Spec.Observation as Observation
import Spec.Observer exposing (isEqual)
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Browser exposing (UrlRequest(..), Document)
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
        |> Subject.withDocument testDocument
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

titleSpec : Spec Model Msg
titleSpec =
  Spec.describe "application title"
  [ scenario "observing the original title" (
      testSubject
    )
    |> it "displays the title" (
      Markup.selectTitle
        |> Observation.expect (isEqual "Some Boring Title")
    )
  , scenario "observing the title after a change" (
      testSubject
    )
    |> when "the title is changed"
      [ target << by [ id "update-title" ]
      , Event.click
      ]
    |> it "updates the title" (
      Markup.selectTitle
        |> Observation.expect (isEqual "My Fun Title")
    )
  ]


clickLinkSpec : Spec Model Msg
clickLinkSpec =
  Spec.describe "handling a url request"
  [ scenario "internal url request" (
      testSubject
    )
    |> when "an internal link is clicked"
      [ target << by [ id "internal-link" ]
      , Event.click
      ]
    |> it "navigates as expected" (
      select << by [ id "fun-page" ]
        |> Markup.expectElement ( Markup.hasText "running" )
    )
  , scenario "external url request" (
      testSubject
    )
    |> when "an external link is clicked"
      [ target << by [ id "external-link" ]
      , Event.click
      ]
    |> it "navigates as expected" (
      Navigation.selectLocation
        |> Observation.expect (isEqual "http://fun-town.org/fun")
    )
  ]


noRequestHandlerSpec : Spec Model Msg
noRequestHandlerSpec =
  Spec.describe "handling a url request"
  [ scenario "no url request handler is set" (
      Subject.initWithKey (testInit () testUrl)
        |> Subject.withDocument testDocument
        |> Subject.withUpdate testUpdate
    )
    |> when "the url is changed"
      [ target << by [ id "internal-link" ]
      , Event.click
      ]
    |> it "fails" (
      select << by [ id "no-page" ]
        |> Markup.expectElement ( Markup.hasText "nothing" )
    )
  ]


testSubject =
  Subject.initWithKey (testInit () testUrl)
    |> Subject.withDocument testDocument
    |> Subject.withUpdate testUpdate
    |> Subject.onUrlChange UrlDidChange
    |> Subject.onUrlRequest UrlChangeRequested


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
  , title: String
  }


type Page
  = Home
  | Fun String


defaultModel : Key -> Model
defaultModel key =
  { key = key
  , page = Home
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


selectSpec : String -> Maybe (Spec Model Msg)
selectSpec name =
  case name of
    "changeUrl" -> Just changeUrlSpec
    "noChangeUrlHandler" -> Just noChangeHandlerSpec
    "changeTitle" -> Just titleSpec
    "clickLink" -> Just clickLinkSpec
    "noRequestHandler" -> Just noRequestHandlerSpec
    _ -> Nothing


main =
  Runner.browserProgram selectSpec