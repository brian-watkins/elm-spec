port module App exposing (..)

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
  , attributes: List String
  , clicks: Int
  , stuff: Stuff
  , page: Page
  , key: Maybe Navigation.Key
  }


type Page
  = Home
  | Fun
  | Awesome
  | Super


defaultModel : Model
defaultModel =
  { name = "Brian"
  , attributes = [ "cool", "fun" ]
  , clicks = 0
  , stuff = noStuff
  , page = Home
  , key = Nothing
  }


type Msg
  = CounterClicked
  | InformClicked
  | Triggered TriggerMessage
  | SendRequest
  | GotStuff (Result Http.Error Stuff)
  | OnUrlChange Url
  | OnUrlRequest UrlRequest
  | NavigateToAwesome
  | SendToExternalLocation String


type alias Stuff =
  { thing: String
  , count: Int
  }


noStuff : Stuff
noStuff =
  { thing = "Nothing"
  , count = 0
  }


init : List String -> ( Model, Cmd Msg )
init initialAttributes =
  ( defaultModel
  , getFakeStuff
  )


initWithPort : List String -> ( Model, Cmd Msg )
initWithPort attributes =
  ( defaultModel
  , inform { attributes = attributes }
  )


initForNavigation : Url -> Navigation.Key -> ( Model, Cmd Msg )
initForNavigation url key =
  let
    maybePage =
      UrlParser.parse routes url
  in
    case maybePage of
      Just page ->
        ( { defaultModel | page = page, key = Just key }, Cmd.none )
      Nothing ->
        ( defaultModel, Cmd.none )


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
        , Html.button [ Attr.id "counter-button", Events.onClick CounterClicked ] [ Html.text "Click me!" ]
        , Html.h3 [ Attr.id "counter-status" ] [ Html.text <| String.fromInt model.clicks ++ " clicks!" ]
        , Html.hr [] []
        , Html.div []
          [ Html.button [ Attr.id "inform-button", Events.onClick InformClicked ] [ Html.text "Inform!" ]
          ]
        , Html.hr [] []
        , Html.div []
          [ Html.button [ Attr.id "send-request", Events.onClick SendRequest ] [ Html.text "Send Request!" ]
          ]
        , Html.div [ Attr.id "stuff-description" ] <| stuffDescription model.stuff
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


stuffDescription : Stuff -> List (Html Msg)
stuffDescription stuff =
  [ Html.text <| "Got " ++ stuff.thing
  , Html.text " "
  , Html.text <| "(" ++ String.fromInt stuff.count ++ ")"
  ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    CounterClicked ->
      ( { model | clicks = model.clicks + 1 }, Cmd.none )
    Triggered message ->
      ( { model | name = message.name }, Cmd.none )
    InformClicked ->
      ( model, inform { attributes = "awesome" :: model.attributes } )
    SendRequest ->
      ( model, getFakeStuff )
    GotStuff (Ok stuff) ->
      ( { model | stuff = stuff }, Cmd.none )
    GotStuff (Err _) ->
      ( { model | stuff = noStuff }, Cmd.none )
    OnUrlChange url ->
      UrlParser.parse routes url
        |> Maybe.withDefault Home
        |> \page ->
          ( { model | page = page }, Cmd.none )
    OnUrlRequest urlRequest ->
      case model.key of
        Just key ->
          case urlRequest of
            Internal url ->
              ( model, Navigation.pushUrl key <| Url.toString url )
            External externalUrl ->
              ( model, Navigation.load externalUrl )
        Nothing ->
          ( model, Cmd.none )
    NavigateToAwesome ->
      case model.key of
        Just key ->
          ( model, Navigation.pushUrl key <| Url.Builder.absolute [ "awesomePage" ] [] )
        Nothing ->
          ( model, Cmd.none )
    SendToExternalLocation url ->
      ( model, Navigation.load url )


getFakeStuff =
  Http.get
    { url = "http://fake.com/fakeStuff"
    , expect = Http.expectJson GotStuff stuffDecoder
    }


stuffDecoder : Json.Decoder Stuff
stuffDecoder =
  Json.map2 Stuff
    ( Json.field "thing" Json.string )
    ( Json.field "count" Json.int )


type alias TriggerMessage =
  { name: String
  }


port triggerStuff : (TriggerMessage -> msg) -> Sub msg
port triggerLocationChange : (String -> msg) -> Sub msg
port inform : { attributes: List String } -> Cmd msg


subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.batch
  [ triggerLocationChange SendToExternalLocation
  , triggerStuff Triggered
  ]