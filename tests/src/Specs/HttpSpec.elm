module Specs.HttpSpec exposing (..)

import Spec exposing (Spec)
import Spec.Subject as Subject
import Spec.Scenario exposing (..)
import Spec.Markup as Markup
import Spec.Observer as Observer
import Spec.Observation.Report as Report
import Spec.Claim exposing (..)
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
import Json.Encode as Encode
import Http
import Specs.Helpers exposing (..)


getSpec : Spec Model Msg
getSpec =
  Spec.describe "HTTP GET"
  [ scenario "a successful HTTP GET" (
      given (
        testSubject getRequest [ successStub ]
      )
      |> when "an http request is triggered"
        [ Markup.target << by [ id "trigger" ]
        , Event.click
        ]
      |> it "receives a stubbed response" (
        Observer.observeModel .response
          |> expect (
            equals <|
              Just 
                { name = "Cool Dude"
                , score = 1034
                }
          )
      )
    )
  , scenario "an unauthorized HTTP GET" (
      given (
        testSubject getRequest [ unauthorizedStub ]
      )
      |> when "an http request is triggered"
        [ Markup.target << by [ id "trigger" ]
        , Event.click
        ]
      |> it "receives a stubbed response" (
        Observer.observeModel .error
          |> expect (
            equals <|
              Just <| Http.BadStatus 401
          )
      )
    )
  ]


getRequest : Cmd Msg
getRequest =
  Http.request
    { method = "GET"
    , headers =
      [ Http.header "X-Fun-Header" "some-fun-value"
      , Http.header "X-Awesome-Header" "some-awesome-value"
      ]
    , url = "http://fake-api.com/stuff"
    , body = Http.stringBody "text/plain;charset=utf-8" ""
    , expect = Http.expectJson ReceivedResponse responseDecoder
    , timeout = Nothing
    , tracker = Nothing
    }


expectRequestSpec : Spec Model Msg
expectRequestSpec =
  Spec.describe "expect a request"
  [ scenario "a request is made" (
      given (
        testSubject getRequest [ successStub ]
      )
      |> when "an http request is triggered"
        [ Markup.target << by [ id "trigger" ]
        , Event.click
        ]
      |> observeThat
        [ it "expects the request" (
            Spec.Http.observeRequests (get "http://fake-api.com/stuff")
              |> expect (isListWithLength 1)
          )
        , it "does not find requests with a different method" (
            Spec.Http.observeRequests (post "http://fake-api.com/stuff")
              |> expect (isListWithLength 0)
          )
        , it "does not find requests with a different url" (
            Spec.Http.observeRequests (get "http://fake-api.com/otherStuff")
              |> expect (isListWithLength 0)
          )
        , it "fails" (
            Spec.Http.observeRequests (get "http://fake-api.com/stuff")
              |> expect (isListWithLength 17)
          )
        ]
    )
  ]


hasHeaderSpec : Spec Model Msg
hasHeaderSpec =
  Spec.describe "hasHeader"
  [ scenario "check headers" (
      given (
        testSubject getRequest [ successStub ]
      )
      |> when "an http request is triggered"
        [ Markup.target << by [ id "trigger" ]
        , Event.click
        ]
      |> observeThat
        [ it "has the expected headers" (
            Spec.Http.observeRequests (get "http://fake-api.com/stuff")
              |> expect (
                isListWhereIndex 0 <| satisfying
                  [ Spec.Http.hasHeader ("X-Fun-Header", "some-fun-value")
                  , Spec.Http.hasHeader ("X-Awesome-Header", "some-awesome-value")
                  ]
              )
          )
        , it "fails to find the header" (
            Spec.Http.observeRequests (get "http://fake-api.com/stuff")
              |> expect (
                \requests ->
                  List.head requests
                    |> Maybe.map (Spec.Http.hasHeader ("X-Missing-Header", "some-fun-value"))
                    |> Maybe.withDefault (Reject <| Report.note "SHOULD NOT GET HERE")
              )
          )
        , it "fails to match the header value" (
            Spec.Http.observeRequests (get "http://fake-api.com/stuff")
              |> expect (
                \requests ->
                  List.head requests
                    |> Maybe.map (Spec.Http.hasHeader ("X-Awesome-Header", "some-fun-value"))
                    |> Maybe.withDefault (Reject <| Report.note "SHOULD NOT GET HERE")
              )
          )
        ]
    )
  ]


hasBodySpec : Spec Model Msg
hasBodySpec =
  let
    postBody =
      Encode.object
      [ ( "name", Encode.string "fun person" )
      , ( "age", Encode.int 88 )
      ]
  in
  Spec.describe "hasBody"
  [ scenario "check body" (
      given (
        testSubject (postRequest postBody) [ successStub ]
      )
      |> when "a request is made"
        [ Markup.target << by [ id "trigger" ]
        , Event.click
        ]
      |> observeThat
        [ it "observes the body of the sent request" (
          Spec.Http.observeRequests (post "http://fake-api.com/stuff")
            |> expect (
              isList
                [ Spec.Http.hasBody "{\"name\":\"fun person\",\"age\":88}"
                ]
            )
          )
        , it "fails to find the wrong body" (
            Spec.Http.observeRequests (post "http://fake-api.com/stuff")
              |> expect (
                isList
                  [ Spec.Http.hasBody "{\"blah\":3}"]
              )
          )
        ]
    )
  ]


postRequest : Json.Value -> Cmd Msg
postRequest body =
  Http.request
    { method = "POST"
    , headers =
      [ Http.header "X-Fun-Header" "some-fun-value"
      , Http.header "X-Awesome-Header" "some-awesome-value"
      ]
    , url = "http://fake-api.com/stuff"
    , body = Http.jsonBody body
    , expect = Http.expectJson ReceivedResponse responseDecoder
    , timeout = Nothing
    , tracker = Nothing
    }



testSubject doRequest stubs =
  Subject.initWithModel defaultModel
    |> Subject.withView testView
    |> Subject.withUpdate (testUpdate doRequest)
    |> Spec.Http.withStubs stubs


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

testUpdate : Cmd Msg -> Msg -> Model -> ( Model, Cmd Msg )
testUpdate doRequest msg model =
  case msg of
    MakeRequest ->
      ( model, doRequest )
    ReceivedResponse response ->
      case response of
        Ok data ->
          ( { model | response = Just data, error = Nothing }, Cmd.none )
        Err err ->
          ( { model | response = Nothing, error = Just err }, Cmd.none )

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
    "hasBody" -> Just hasBodySpec
    _ -> Nothing


main =
  Runner.browserProgram selectSpec