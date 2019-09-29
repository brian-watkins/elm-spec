module Specs.HttpSpec exposing (main)

import Spec exposing (Spec)
import Spec.Subject as Subject
import Spec.Scenario exposing (..)
import Spec.Markup as Markup
import Spec.Observation as Observation
import Spec.Observer exposing (..)
import Spec.Markup.Selector exposing (..)
import Spec.Markup.Event as Event
import Spec.Http
import Spec.Http.Stub as Stub
import Spec.Http.Route exposing (..)
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Runner
import Json.Decode as Json
import Http


getSpec : Spec Model Msg
getSpec =
  Spec.describe "HTTP GET"
  [ scenario "a successful HTTP GET" (
      Subject.initWithModel { response = Nothing }
        |> Subject.withView testView
        |> Subject.withUpdate testUpdate
        |> Spec.Http.withStubs [ successStub ]
    )
    |> when "an http request is triggered"
      [ target << by [ id "trigger" ]
      , Event.click
      ]
    |> it "received a stubbed response" (
      Observation.selectModel
        |> Observation.mapSelection .response
        |> Observation.expect (
          isEqual <|
            Just 
              { name = "Cool Dude"
              , score = 1034
              }
        )
    )
  ]

successStub =
  Stub.for (get "http://fake-api.com/stuff")
    |> Stub.withBody "{\"name\":\"Cool Dude\",\"score\":1034}"

type alias Model =
  { response: Maybe ResponseObject
  }

type alias ResponseObject =
  { name: String
  , score: Int
  }

type Msg
  = MakeRequest
  | ReceivedResponse (Result Http.Error ResponseObject)

testView : Model -> Html Msg
testView model =
  Html.div []
  [ Html.button [ Attr.id "trigger", Events.onClick MakeRequest ]
    [ Html.text "Click to make request!" ]
  ]

testUpdate : Msg -> Model -> ( Model, Cmd Msg )
testUpdate msg model =
  case msg of
    MakeRequest ->
      ( model, requestObject )
    ReceivedResponse response ->
      ( { model | response = Result.toMaybe response }, Cmd.none )

requestObject : Cmd Msg
requestObject =
  Http.get
    { url = "http://fake-api.com/stuff"
    , expect = Http.expectJson ReceivedResponse responseDecoder
    }

responseDecoder : Json.Decoder ResponseObject
responseDecoder =
  Json.map2 ResponseObject
    ( Json.field "name" Json.string )
    ( Json.field "score" Json.int )

selectSpec : String -> Maybe (Spec Model Msg)
selectSpec name =
  case name of
    "get" -> Just getSpec
    _ -> Nothing


main =
  Runner.browserProgram selectSpec