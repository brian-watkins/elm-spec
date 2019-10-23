module Specs.HttpSpec exposing (..)

import Spec exposing (Spec)
import Spec.Subject as Subject
import Spec.Scenario exposing (..)
import Spec.Markup as Markup
import Spec.Observation as Observation
import Spec.Observation.Report as Report
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
      given (
        Subject.initWithModel defaultModel
          |> Subject.withView testView
          |> Subject.withUpdate testUpdate
          |> Spec.Http.withStubs [ successStub ]
      )
      |> when "an http request is triggered"
        [ target << by [ id "trigger" ]
        , Event.click
        ]
      |> it "receives a stubbed response" (
        Observation.selectModel .response
          |> expect (
            isEqual <|
              Just 
                { name = "Cool Dude"
                , score = 1034
                }
          )
      )
    )
  , scenario "an unauthorized HTTP GET" (
      given (
        Subject.initWithModel defaultModel
          |> Subject.withView testView
          |> Subject.withUpdate testUpdate
          |> Spec.Http.withStubs [ unauthorizedStub ]
      )
      |> when "an http request is triggered"
        [ target << by [ id "trigger" ]
        , Event.click
        ]
      |> it "receives a stubbed response" (
        Observation.selectModel .error
          |> expect (
            isEqual <|
              Just <| Http.BadStatus 401
          )
      )
    )
  ]

expectRequestSpec : Spec Model Msg
expectRequestSpec =
  Spec.describe "expect a request"
  [ scenario "a request is made" (
      given (
        Subject.initWithModel defaultModel
          |> Subject.withView testView
          |> Subject.withUpdate testUpdate
          |> Spec.Http.withStubs [ successStub ]
      )
      |> when "an http request is triggered"
        [ target << by [ id "trigger" ]
        , Event.click
        ]
      |> observeThat
        [ it "expects the request" (
            Spec.Http.expect (get "http://fake-api.com/stuff") (
              isListWithLength 1
            )
          )
        , it "does not find requests with a different method" (
            Spec.Http.expect (post "http://fake-api.com/stuff") (
              isListWithLength 0
            )
          )
        , it "does not find requests with a different url" (
            Spec.Http.expect (get "http://fake-api.com/otherStuff") (
              isListWithLength 0
            )
          )
        , it "fails" (
            Spec.Http.expect (get "http://fake-api.com/stuff") (
              isListWithLength 17
            )
          )
        ]
    )
  ]

hasHeaderSpec : Spec Model Msg
hasHeaderSpec =
  Spec.describe "hasHeader"
  [ scenario "check headers" (
      given (
        Subject.initWithModel defaultModel
          |> Subject.withView testView
          |> Subject.withUpdate testUpdate
          |> Spec.Http.withStubs [ successStub ]
      )
      |> when "an http request is triggered"
        [ target << by [ id "trigger" ]
        , Event.click
        ]
      |> observeThat
        [ it "has the expected headers" (
            Spec.Http.expect (get "http://fake-api.com/stuff") (
              isListWhereIndex 0 <| satisfying
                [ Spec.Http.hasHeader ("X-Fun-Header", "some-fun-value")
                , Spec.Http.hasHeader ("X-Awesome-Header", "some-awesome-value")
                ]
            )
          )
        , it "fails to find the header" (
            Spec.Http.expect (get "http://fake-api.com/stuff") (
              \requests ->
                List.head requests
                  |> Maybe.map (Spec.Http.hasHeader ("X-Missing-Header", "some-fun-value"))
                  |> Maybe.withDefault (Reject <| Report.note "SHOULD NOT GET HERE")
            )
          )
        , it "fails to match the header value" (
            Spec.Http.expect (get "http://fake-api.com/stuff") (
              \requests ->
                List.head requests
                  |> Maybe.map (Spec.Http.hasHeader ("X-Awesome-Header", "some-fun-value"))
                  |> Maybe.withDefault (Reject <| Report.note "SHOULD NOT GET HERE")
            )
          )
        ]
    )
  ]


successStub =
  Stub.for (get "http://fake-api.com/stuff")
    |> Stub.withBody "{\"name\":\"Cool Dude\",\"score\":1034}"

unauthorizedStub =
  Stub.for (get "http://fake-api.com/stuff")
    |> Stub.withStatus 401

type alias Model =
  { response: Maybe ResponseObject
  , error: Maybe Http.Error
  }

defaultModel =
  { response = Nothing
  , error = Nothing
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
      case response of
        Ok data ->
          ( { model | response = Just data, error = Nothing }, Cmd.none )
        Err err ->
          ( { model | response = Nothing, error = Just err }, Cmd.none )

requestObject : Cmd Msg
requestObject =
  Http.request
    { method = "GET"
    , headers =
      [ Http.header "X-Fun-Header" "some-fun-value"
      , Http.header "X-Awesome-Header" "some-awesome-value"
      ]
    , url = "http://fake-api.com/stuff"
    , body = Http.emptyBody
    , expect = Http.expectJson ReceivedResponse responseDecoder
    , timeout = Nothing
    , tracker = Nothing
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
    "expectRequest" -> Just expectRequestSpec
    "hasHeader" -> Just hasHeaderSpec
    _ -> Nothing


main =
  Runner.browserProgram selectSpec