module Specs.HttpRouteSpec exposing (main)

import Spec exposing (..)
import Spec.Setup as Setup
import Spec.Markup as Markup
import Spec.Observer as Observer
import Spec.Claim as Claim exposing (..)
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
import Url.Builder
import Specs.Helpers exposing (..)


regexSpec : Spec Model Msg
regexSpec =
  Spec.describe "route defined by regex"
  [ scenario "matches the regex" (
      given (
        testSubject (getRequestTo "http://fake-api.com/fun" [ ("activity", "running") ])
          [ successStubRoute (route "GET" <| Matching "http:\\/\\/fake\\-api\\.com\\/fun\\?.*") ]
      )
      |> whenTheRequestIsTriggered
      |> observeThat
        [ itReceivesTheStubbedResponse
        , itObservesTheRequest (route "GET" <| Matching "http:\\/\\/fake\\-api\\.com\\/fun\\?.*")
        ]
    )
  , scenario "does not match the regex" (
      given (
        testSubject (getRequestTo "http://fake-api.com/fun" [ ("activity", "running") ])
          [ successStubRoute (route "GET" <| Matching "http:\\/\\/fake\\-api\\.com\\/fun\\/") ]
      )
      |> whenTheRequestIsTriggered
      |> observeThat
        [ itDoesNotReceiveTheStubbResponse
        , itDoesNotObserveTheRequest (route "GET" <| Matching "http:\\/\\/fake\\-api\\.com\\/fun\\/")
        ]
    )
  , scenario "it fails to match the regex" (
      given (
        testSubject (getRequestTo "http://fake-api.com/fun" [ ("activity", "running") ]) []
      )
      |> whenTheRequestIsTriggered
      |> itObservesTheRequest (route "GET" <| Matching "http:\\/\\/fake\\-api\\.com\\/awesome\\?.*")
    )
  ]


badRegexSpec : Spec Model Msg
badRegexSpec =
  Spec.describe "bad regex"
  [ scenario "the regex in an observer doesn't compile" (
      given (
        testSubject (getRequestTo "http://fake-api.com/fun" [ ("activity", "running") ]) []
      )
      |> whenTheRequestIsTriggered
      |> itObservesTheRequest (route "GET" <| Matching "[A--Z]")
    )
  , scenario "the regex in a stub doesn't compile and there are no steps" (
      given (
        testSubject (getRequestTo "http://fake-api.com/fun" [ ("activity", "running") ])
          [ successStubRoute (route "GET" <| Matching "[1")]
      )
      |> itReceivesTheStubbedResponse
    )
  , scenario "the regex in a stub doesn't compile and there are steps" (
      given (
        testSubject (getRequestTo "http://fake-api.com/fun" [ ("activity", "running") ])
          [ successStubRoute (route "GET" <| Matching "[2")]
      )
      |> whenTheRequestIsTriggered
      |> itReceivesTheStubbedResponse
    )
  ]


urlSpec : Spec Model Msg
urlSpec =
  Spec.describe "url"
  [ scenario "the claim about the url should be accepted" (
      given (
        testSubject (getRequestTo "http://fake.com/fun" [ ("sport", "bowling") ]) []
      )
      |> whenTheRequestIsTriggered
      |> it "accepts the claim about the request url" (
        Spec.Http.observeRequests (route "GET" <| Matching "fake\\.com\\/fun")
          |> expect (isListWhere
            [ Spec.Http.url <| isStringContaining 1 "sport=bowling"
            ]
          )
      )
    )
  , scenario "the claim about the url should be rejected" (
      given (
        testSubject (getRequestTo "http://fake.com/fun" [ ("sport", "cross-country skiing") ]) []
      )
      |> whenTheRequestIsTriggered
      |> it "accepts the claim about the request url" (
        Spec.Http.observeRequests (route "GET" <| Matching "fake\\.com\\/fun")
          |> expect (isListWhere
            [ Spec.Http.url <| isStringContaining 1 "sport=cycling"
            ]
          )
      )
    )
  ]


testSubject doRequest stubs =
  Setup.initWithModel defaultModel
    |> Setup.withView testView
    |> Setup.withUpdate (testUpdate doRequest)
    |> Stub.serve stubs


successStubRoute route =
  Stub.for route
    |> Stub.withBody (Stub.withText "{\"name\":\"Awesome Person\",\"score\":1944}")


whenTheRequestIsTriggered =
  when "an http request is triggered"
    [ Markup.target << by [ id "trigger" ]
    , Event.click
    ]


getRequestTo : String -> List (String, String) -> Cmd Msg
getRequestTo origin params =
  Http.request
    { method = "GET"
    , headers =
      [ Http.header "X-Fun-Header" "some-fun-value"
      , Http.header "X-Awesome-Header" "some-awesome-value"
      ]
    , url = origin ++ toQueryString params
    , body = Http.emptyBody
    , expect = Http.expectJson ReceivedResponse responseDecoder
    , timeout = Nothing
    , tracker = Nothing
    }


toQueryString : List (String, String) -> String
toQueryString params =
  List.map (\(name, value) -> Url.Builder.string name value) params
    |> Url.Builder.toQuery


itReceivesTheStubbedResponse =
  it "receives a stubbed response" (
    Observer.observeModel .responses
      |> expect (isListWhere
        [ equals
          { name = "Awesome Person"
          , score = 1944
          }
        ]
      )
  )


itObservesTheRequest route =
  it "observes the request" (
    Spec.Http.observeRequests route
      |> expect (isListWithLength 1)
  )


itDoesNotObserveTheRequest route =
  it "observes no requests" (
    Spec.Http.observeRequests route
      |> expect (isListWithLength 0)
  )


itDoesNotReceiveTheStubbResponse =
  it "does not receive the stubbed response" (
    Observer.observeModel .responses
      |> expect (isListWithLength 0)
  )


type alias Model =
  { responses: List ResponseObject
  , error: Maybe Http.Error
  }


defaultModel =
  { responses = []
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
          ( { model | responses = data :: model.responses, error = Nothing }, Cmd.none )
        Err err ->
          ( { model | error = Just err }, Cmd.none )


responseDecoder : Json.Decoder ResponseObject
responseDecoder =
  Json.map2 ResponseObject
    ( Json.field "name" Json.string )
    ( Json.field "score" Json.int )


selectSpec : String -> Maybe (Spec Model Msg)
selectSpec name =
  case name of
    "regex" -> Just regexSpec
    "badRegex" -> Just badRegexSpec
    "url" -> Just urlSpec
    _ -> Nothing


main =
  Runner.browserProgram selectSpec