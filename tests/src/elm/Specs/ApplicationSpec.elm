module Specs.ApplicationSpec exposing (..)

import Spec exposing (..)
import Spec.Setup as Setup
import Spec.Claim as Claim exposing (isStringContaining, isSomethingWhere)
import Spec.Markup as Markup
import Spec.Markup.Selector exposing (..)
import Spec.Markup.Event as Event
import Spec.Navigator as Navigator
import Spec.Observer as Observer
import Spec.Report as Report
import Spec.Command as Command
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
        Setup.initForApplication (testInit ())
          |> Setup.withDocument testDocument
          |> Setup.withUpdate testUpdate
          |> Setup.forNavigation { onUrlChange = UrlDidChange, onUrlRequest = UrlChangeRequested }
          |> Setup.withLocation (testUrl "/fun/reading")
      )
      |> observeThat
        [ it "sets the location to the given url" (
            Navigator.observe
              |> expect (Navigator.location <| equals "http://my-test-app.com/fun/reading")
          )
        , it "renders the view based on the url" (
            Markup.observeElement
              |> Markup.query << by [ id "fun-page" ]
              |> expect (isSomethingWhere <| Markup.text <| isStringContaining 1 "reading")
          )
        ]
    )
  ]


changeUrlSpec : Spec Model Msg
changeUrlSpec =
  Spec.describe "on url change"
  [ scenario "by default" (
      given testSubject
        |> observeThat
          [ it "does not show anything fun" (
              Markup.observeElement
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
            Navigator.observe
              |> expect (Navigator.location <| equals "http://my-test-app.com/fun/bowling")
          )
        , it "shows a different page" (
            Markup.observeElement
              |> Markup.query << by [ id "fun-page" ]
              |> expect (isSomethingWhere <| Markup.text <| isStringContaining 1 "bowling")
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
                |> expect (isSomethingWhere <| Markup.text <| isStringContaining 1 "swimming")
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
            Navigator.observe
              |> expect (Navigator.title <| equals "Some Boring Title")
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
            Navigator.observe
              |> expect (Navigator.title <| equals "My Fun Title")
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
            Navigator.observe
              |> expect (Navigator.location <| equals "http://my-test-app.com/fun/running")
          )
        , it "navigates as expected" (
            Markup.observeElement
              |> Markup.query << by [ id "fun-page" ]
              |> expect (isSomethingWhere <| Markup.text <| isStringContaining 1 "running")
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
            Navigator.observe
              |> expect (Navigator.location <| equals "http://fun-town.org/fun")
          )
        ]
    )
  ]


noNavigationConfigSpec : Spec Model Msg
noNavigationConfigSpec =
  Spec.describe "no navigation config is set"
  [ scenario "initForApplication is used and a link is clicked" (
      given (
        Setup.initForApplication (testInit ())
          |> Setup.withDocument testDocument
          |> Setup.withUpdate testUpdate
      )
      |> when "the url is changed"
        [ Markup.target << by [ id "internal-link" ]
        , Event.click
        ]
      |> itFails
    )
  , scenario "initForApplication is used and a url is pushed" (
      given (
        Setup.initForApplication (testInit ())
          |> Setup.withDocument testDocument
          |> Setup.withUpdate testUpdate
      )
      |> when "the url is changed"
        [ Markup.target << by [ id "push-url-button" ]
        , Event.click
        ]
      |> itFails
    )
  , scenario "any other init function is used" (
      given (
        Setup.initWithModel elementModel
          |> Setup.withDocument testDocument
          |> Setup.withUpdate testUpdate
          |> Setup.withLocation (testUrl "/")
      )
      |> when "an internal link is clicked"
        [ Markup.target << by [ id "internal-link" ]
        , Event.click
        ]
      |> observeThat
        [ it "updates the location" (
            Navigator.observe
              |> expect (Navigator.location <| equals "http://my-test-app.com/fun/running")
          )
        , it "updates the view to show we are on some other page" (
            Markup.observeElement
              |> Markup.query << by [ tag "body" ]
              |> expect (isSomethingWhere <| Markup.text <| equals "[Navigated to a page outside the control of the Elm program: http://my-test-app.com/fun/running]")
          )
        ]
    )
  , scenario "any other init is used and external url request" (
      given (
        Setup.initWithModel elementModel
          |> Setup.withDocument testDocument
          |> Setup.withUpdate testUpdate
          |> Setup.withLocation (testUrl "/")
      )
      |> when "an external link is clicked"
        [ Markup.target << by [ id "external-link" ]
        , Event.click
        ]
      |> observeThat
        [ it "navigates as expected" (
          Navigator.observe
              |> expect (Navigator.location <| equals "http://fun-town.org/fun")
          )
        , it "updates the view to show we are on some other page" (
            Markup.observeElement
              |> Markup.query << by [ tag "body" ]
              |> expect (isSomethingWhere <| Markup.text <| equals "[Navigated to a page outside the control of the Elm program: http://fun-town.org/fun]")
          )
        ]
    )
  ]


itFails =
  it "fails" (
    Observer.observeModel (always True)
      |> expect (always << Claim.Reject <| Report.note "Should fail before this!")
  )


testSubject =
  Setup.initForApplication (testInit ())
    |> Setup.withDocument testDocument
    |> Setup.withUpdate testUpdate
    |> Setup.forNavigation { onUrlChange = UrlDidChange, onUrlRequest = UrlChangeRequested }
    |> Setup.withLocation (testUrl "/")


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
  { key: Maybe Key
  , page: Page
  , title: String
  }


type Page
  = Home
  | Fun String


defaultModel : Url -> Key -> Model
defaultModel url key =
  { key = Just key
  , page = toPage url
  , title = "Some Boring Title"
  }


elementModel : Model
elementModel =
  { key = Nothing
  , page = Home
  , title = "Some Element"
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
          case model.key of
            Just key ->
              ( model, Browser.Navigation.pushUrl key <| Url.toString url )
            Nothing ->
              ( model, Cmd.none )
        External url ->
          ( model, Browser.Navigation.load url )
    DoPushUrl ->
      case model.key of
        Just key ->
          ( model, Browser.Navigation.pushUrl key <| Url.Builder.absolute [ "fun", "bowling" ] [] )
        Nothing ->
          ( model, Cmd.none )
    DoReplaceUrl ->
      case model.key of
        Just key ->
          ( model, Browser.Navigation.replaceUrl key <| Url.Builder.absolute [ "fun", "swimming" ] []  )
        Nothing ->
          ( model, Cmd.none )
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
    "changeTitle" -> Just titleSpec
    "clickLink" -> Just clickLinkSpec
    "noNavigationConfig" -> Just noNavigationConfigSpec
    _ -> Nothing


main =
  Runner.browserProgram selectSpec