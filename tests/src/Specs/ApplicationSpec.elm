module Specs.ApplicationSpec exposing (..)

import Spec exposing (..)
import Spec.Subject as Subject
import Spec.Claim as Claim
import Spec.Markup as Markup
import Spec.Markup.Selector exposing (..)
import Spec.Markup.Event as Event
import Spec.Markup.Navigation as Navigation
import Spec.Observer as Observer
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Browser exposing (UrlRequest(..), Document)
import Browser.Navigation exposing (Key)
import Runner
import Url exposing (Url)
import Url.Parser exposing ((</>))
import Url.Builder
import Specs.Helpers exposing (..)


applyGivenUrlSpec : Spec Model Msg
applyGivenUrlSpec =
  Spec.describe "given a url"
  [ scenario "a url is provided" (
      given (
        Subject.initForApplication (testInit ())
          |> Subject.withDocument testDocument
          |> Subject.withUpdate testUpdate
          |> Subject.onUrlChange UrlDidChange
          |> Subject.onUrlRequest UrlChangeRequested
          |> Subject.withLocation (testUrl "/fun/reading")
      )
      |> observeThat
        [ it "sets the location to the given url" (
            Navigation.observeLocation
              |> expect (equals "http://my-test-app.com/fun/reading")
          )
        , it "renders the view based on the url" (
            Markup.observeElement
              |> Markup.query << by [ id "fun-page" ]
              |> expect ( Markup.hasText "reading" )
          )
        ]
    )
  ]


noChangeHandlerSpec : Spec Model Msg
noChangeHandlerSpec =
  Spec.describe "on url change"
  [ scenario "no url change handler is set" (
      given (
        Subject.initForApplication (testInit ())
          |> Subject.withDocument testDocument
          |> Subject.withUpdate testUpdate
      )
      |> when "the url is changed"
        [ Markup.target << by [ id "push-url-button" ]
        , Event.click
        ]
      |> it "fails" (
          Markup.observeElement
            |> Markup.query << by [ id "no-page" ]
            |> expect ( Markup.hasText "bowling" )
        )
    )
  ]


changeUrlSpec : Spec Model Msg
changeUrlSpec =
  Spec.describe "on url change"
  [ scenario "by default" (
      given testSubject
        |> observeThat
          [ it "does not show anything fun" (
              Markup.observe
                |> Markup.query << by [ id "fun-page" ]
                |> expect Claim.isNothing
            )
          ]
    )
  , scenario "use pushUrl to navigate" (
      given (
        testSubject
      )
      |> when "the url is changed"
        [ Markup.target << by [ id "push-url-button" ]
        , Event.click
        ]
      |> observeThat
        [ it "updates the location" (
            Navigation.observeLocation
              |> expect (equals "http://my-test-app.com/fun/bowling")
          )
        , it "shows a different page" (
            Markup.observeElement
              |> Markup.query << by [ id "fun-page" ]
              |> expect ( Markup.hasText "bowling" )
          )
        ]
    )
  , scenario "use replaceUrl to navigate" (
      given testSubject
        |> when "the url is changed"
          [ Markup.target << by [ id "replace-url-button" ]
          , Event.click
          ]
        |> observeThat
          [ it "shows a different page" (
              Markup.observeElement
                |> Markup.query << by [ id "fun-page" ]
                |> expect ( Markup.hasText "swimming" )
            )
          ]
    )
  ]

titleSpec : Spec Model Msg
titleSpec =
  Spec.describe "application title"
  [ scenario "observing the original title" (
      given (
        testSubject
      )
      |> observeThat
        [ it "displays the title" (
            Markup.observeTitle
              |> expect (equals "Some Boring Title")
          )
        ]
    )
  , scenario "observing changes to the title" (
      given (
        testSubject
      )
      |> when "the title is changed"
        [ Markup.target << by [ id "update-title" ]
        , Event.click
        ]
      |> observeThat
        [ it "updates the title" (
            Markup.observeTitle
              |> expect (equals "My Fun Title")
          )
        ]
    ) 
  ]


clickLinkSpec : Spec Model Msg
clickLinkSpec =
  Spec.describe "handling a url request"
  [ scenario "internal url request" (
      given testSubject
      |> when "an internal link is clicked"
        [ Markup.target << by [ id "internal-link" ]
        , Event.click
        ]
      |> observeThat
        [ it "updates the location" (
            Navigation.observeLocation
              |> expect (equals "http://my-test-app.com/fun/running")
          )
        , it "navigates as expected" (
            Markup.observeElement
              |> Markup.query << by [ id "fun-page" ]
              |> expect ( Markup.hasText "running" )
          )
        ]
    )
  , scenario "external url request" (
      given (
        testSubject
      )
      |> when "an external link is clicked"
        [ Markup.target << by [ id "external-link" ]
        , Event.click
        ]
      |> observeThat
        [ it "navigates as expected" (
            Navigation.observeLocation
              |> expect (equals "http://fun-town.org/fun")
          )
        ]
    )
  ]


noRequestHandlerSpec : Spec Model Msg
noRequestHandlerSpec =
  Spec.describe "handling a url request"
  [ scenario "no url request handler is set" (
      given (
        Subject.initForApplication (testInit ())
          |> Subject.withDocument testDocument
          |> Subject.withUpdate testUpdate
      )
      |> when "the url is changed"
        [ Markup.target << by [ id "internal-link" ]
        , Event.click
        ]
      |> observeThat
        [ it "fails" (
            Markup.observeElement
              |> Markup.query << by [ id "no-page" ]
              |> expect ( Markup.hasText "nothing" )
          )
        ]
    )
  ]


testSubject =
  Subject.initForApplication (testInit ())
    |> Subject.withDocument testDocument
    |> Subject.withUpdate testUpdate
    |> Subject.onUrlChange UrlDidChange
    |> Subject.onUrlRequest UrlChangeRequested
    |> Subject.withLocation (testUrl "/")


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


selectSpec : String -> Maybe (Spec Model Msg)
selectSpec name =
  case name of
    "applyUrl" -> Just applyGivenUrlSpec
    "changeUrl" -> Just changeUrlSpec
    "noChangeUrlHandler" -> Just noChangeHandlerSpec
    "changeTitle" -> Just titleSpec
    "clickLink" -> Just clickLinkSpec
    "noRequestHandler" -> Just noRequestHandlerSpec
    _ -> Nothing


main =
  Runner.browserProgram selectSpec