port module App exposing (..)

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Http
import Json.Decode as Json
import Url exposing (Url)
import Url.Parser as UrlParser exposing (Parser)
import Browser exposing (UrlRequest)
import Browser.Navigation as Navigation


type alias Model =
  { name: String
  , attributes: List String
  , clicks: Int
  , stuff: Stuff
  , page: Page
  }


type Page
  = Home
  | Fun


defaultModel : Model
defaultModel =
  { name = "Brian"
  , attributes = [ "cool", "fun" ]
  , clicks = 0
  , stuff = noStuff
  , page = Home
  }


type Msg
  = CounterClicked
  | InformClicked
  | Triggered TriggerMessage
  | SendRequest
  | GotStuff (Result Http.Error Stuff)
  | OnUrlChange Url
  | OnUrlRequest UrlRequest


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


initForNavigation : Url -> Navigation.Key -> ( Model, Cmd Msg )
initForNavigation url key =
  let
    maybePage =
      UrlParser.parse (UrlParser.map Fun <| UrlParser.s "funPage") url
  in
    case maybePage of
      Just page ->
        ( { defaultModel | page = page }, Cmd.none )
      Nothing ->
        ( defaultModel, Cmd.none )



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
        ]
    Fun ->
      Html.div []
        [ Html.h1 [ Attr.id "title" ] [ Html.text "On the fun page!" ]
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
    OnUrlChange _ ->
      ( model, Cmd.none )
    OnUrlRequest _ ->
      ( model, Cmd.none )


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
port inform : { attributes: List String } -> Cmd msg

subscriptions : Model -> Sub Msg
subscriptions model =
  triggerStuff Triggered