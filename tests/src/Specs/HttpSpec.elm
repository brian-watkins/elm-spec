module Specs.HttpSpec exposing (main)

import Spec exposing (..)
import Spec.Setup as Setup
import Spec.Markup as Markup
import Spec.Observer as Observer
import Spec.Report as Report
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
import Json.Encode as Encode
import Http
import Url.Builder
import Dict
import Specs.Helpers exposing (..)


getSpec : Spec Model Msg
getSpec =
  Spec.describe "HTTP GET"
  [ scenario "a successful HTTP GET" (
      given (
        testSubject getRequest [ successStub ]
      )
      |> whenTheRequestIsTriggered
      |> it "receives a stubbed response" (
        Observer.observeModel .responses
          |> expect ( isListWhere
            [ equals 
              { name = "Cool Dude"
              , score = 1034
              }
            ]
          )
      )
    )
  , scenario "multiple stubbed requests" (
      given (
        testSubject (Cmd.batch [ getRequest, getOtherRequest ]) [ successStub, otherSuccessStub ]
      )
      |> whenTheRequestIsTriggered
      |> it "receives the stubbed responses" (
        Observer.observeModel .responses
          |> expect ( isListWhere
            [ equals { name = "Cool Dude", score = 1034 }
            , equals { name = "Fun Person", score = 971 }
            ]
          )
      )
    )
  , scenario "an unauthorized HTTP GET" (
      given (
        testSubject getRequest [ unauthorizedStub ]
      )
      |> whenTheRequestIsTriggered
      |> it "receives a stubbed response" (
        Observer.observeModel .error
          |> expect (
            equals (Just <| Http.BadStatus 401)
          )
      )
    )
  ]


getRequest : Cmd Msg
getRequest =
  getRequestWithTimeout Nothing


getRequestWithTimeout : Maybe Float -> Cmd Msg
getRequestWithTimeout timeout =
  Http.request
    { method = "GET"
    , headers =
      [ Http.header "X-Fun-Header" "some-fun-value"
      , Http.header "X-Awesome-Header" "some-awesome-value"
      ]
    , url = "http://fake-api.com/stuff"
    , body = Http.emptyBody
    , expect = Http.expectJson ReceivedResponse responseDecoder
    , timeout = timeout
    , tracker = Nothing
    }


getOtherRequest : Cmd Msg
getOtherRequest =
  Http.request
    { method = "GET"
    , headers =
      [ Http.header "X-Super-Header" "some-super-value"
      , Http.header "X-Awesome-Header" "some-awesome-value"
      ]
    , url = "http://fake-api.com/fun"
    , body = Http.emptyBody
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
      |> when "http requests are triggered"
        [ Markup.target << by [ id "trigger" ]
        , Event.click
        , Event.click
        , Event.click
        ]
      |> observeThat
        [ it "expects the request" (
            Spec.Http.observeRequests (get "http://fake-api.com/stuff")
              |> expect (isListWithLength 3)
          )
        , it "uses the route function as expected" (
            Spec.Http.observeRequests (route "GET" "http://fake-api.com/stuff")
              |> expect (isListWithLength 3)
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


errorStubSpec : Spec Model Msg
errorStubSpec =
  Spec.describe "stub an error"
  [ scenario "the request results in a network error" (
      given (
        testSubject getRequest [ networkErrorStub ]
      )
      |> whenTheRequestIsTriggered
      |> it "receives an error" (
        Observer.observeModel .error
          |> expect (equals <| Just Http.NetworkError)
      )
    )
  , scenario "the request results in a timeout" (
      given (
        testSubject (getRequestWithTimeout <| Just 100) [ timeoutStub ]
      )
      |> whenTheRequestIsTriggered
      |> it "receives a timeout error" (
        Observer.observeModel .error
          |> expect (equals <| Just Http.Timeout)
      )
    )
  ]


networkErrorStub =
  Stub.for (get "http://fake-api.com/stuff")
    |> Stub.withNetworkError


timeoutStub =
  Stub.for (get "http://fake-api.com/stuff")
    |> Stub.withTimeout


headerStubSpec : Spec Model Msg
headerStubSpec =
  Spec.describe "stubbed headers"
  [ scenario "stub headers" (
      given (
        testSubject fancyRequest [ headerStub ]
      )
      |> whenTheRequestIsTriggered
      |> it "receives the metadata" (
        Observer.observeModel .metadata
          |> expect (\metadata ->
            case metadata of
              Just data ->
                Dict.fromList
                  [ ("X-Fun-Header", "fun-value" )
                  , ("X-Super-Header", "super-value" )
                  , ("Location", "http://fun-place.com/fun")
                  ]
                |> equals data.headers
              Nothing ->
                Claim.Reject <| Report.note "No Metadata!"
          )
      )
    )
  ]


headerStub =
  Stub.for (get "http://fake-api.com/fake/stuff")
    |> Stub.withHeader ( "X-Fun-Header", "fun-value" )
    |> Stub.withHeader ( "X-Super-Header", "super-value" )
    |> Stub.withHeader ( "Location", "http://fun-place.com/fun" )


fancyRequest : Cmd Msg
fancyRequest =
  Http.request
    { method = "GET"
    , headers = []
    , url = "http://fake-api.com/fake/stuff"
    , body = Http.stringBody "text/plain;charset=utf-8" ""
    , expect = Http.expectStringResponse ReceivedMetadata responseHandler
    , timeout = Nothing
    , tracker = Nothing
    }


responseHandler : Http.Response String -> Result () Http.Metadata
responseHandler response =
  case response of
    Http.GoodStatus_ metadata body ->
      Ok metadata
    _ ->
      Err ()


abstainSpec : Spec Model Msg
abstainSpec =
  Spec.describe "abstain"
  [ scenario "observe what happens while a request is in progress" (
      given (
        testSubject getRequest [ abstainedStub ]
      )
      |> whenTheRequestIsTriggered
      |> observeThat
        [ it "observes the request" (
            Spec.Http.observeRequests (get "http://fake-api.com/stuff")
              |> expect (isListWithLength 1)
          )
        , it "does something while the request is in progress" (
            Markup.observeElement
              |> Markup.query << by [ id "request-status" ]
              |> expect (Markup.hasText "In Progress")
          )
        ]
    )
  ]


abstainedStub =
  Stub.for (get "http://fake-api.com/stuff")
    |> Stub.abstain


hasHeaderSpec : Spec Model Msg
hasHeaderSpec =
  Spec.describe "hasHeader"
  [ scenario "check headers" (
      given (
        testSubject getRequest [ successStub ]
      )
      |> whenTheRequestIsTriggered
      |> observeThat
        [ it "has the expected headers" (
            Spec.Http.observeRequests (get "http://fake-api.com/stuff")
              |> expect (
                isListWhereItemAt 0 <| satisfying
                  [ Spec.Http.header "X-Fun-Header" <| isSomethingWhere <| equals "some-fun-value"
                  , Spec.Http.header "X-Awesome-Header" <| isSomethingWhere <| equals "some-awesome-value"
                  ]
              )
          )
        , it "fails to find the header" (
            Spec.Http.observeRequests (get "http://fake-api.com/stuff")
              |> expect (isListWhere
                [ Spec.Http.header "X-Missing-Header" isNothing
                ]
              )
          )
        , it "fails to match the header value" (
            Spec.Http.observeRequests (get "http://fake-api.com/stuff")
              |> expect (isListWhere
                [ Spec.Http.header "X-Awesome-Header" <| isSomethingWhere <| equals "some-fun-value"
                ]
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
  [ scenario "empty body" (
      given (
        testSubject getRequest [ successStub ]
      )
      |> whenTheRequestIsTriggered
      |> observeThat
        [ it "fails to find a string body" (
            Spec.Http.observeRequests (get "http://fake-api.com/stuff")
              |> expect (
                isListWhere
                  [ Spec.Http.stringBody <| equals "some string body that it does not have"
                  ]
              )
          )
        , it "fails to find a json body" (
            Spec.Http.observeRequests (get "http://fake-api.com/stuff")
              |> expect (
                isListWhere
                  [ Spec.Http.jsonBody Json.string <| equals "some json that it does not have"
                  ]
              )
          )
        ]
    )
  , scenario "string body with json" (
      given (
        testSubject (postRequestWithJson postBody) []
      )
      |> whenTheRequestIsTriggered
      |> observeThat
        [ it "observes the body of the sent request" (
            Spec.Http.observeRequests (post "http://fake-api.com/stuff")
              |> expect (
                isListWhere
                  [ Spec.Http.stringBody <| equals "{\"name\":\"fun person\",\"age\":88}"
                  ]
              )
          )
        , it "fails to find the wrong body" (
            Spec.Http.observeRequests (post "http://fake-api.com/stuff")
              |> expect (
                isListWhere
                  [ Spec.Http.stringBody <| equals "{\"blah\":3}"
                  ]
              )
          )
        , it "observes the body as json" (
            Spec.Http.observeRequests (post "http://fake-api.com/stuff")
              |> expect (
                isListWhere
                  [ Spec.Http.jsonBody (Json.field "age" Json.int) <| equals 88
                  ]
              )
          )
        , it "fails when the decoder fails" (
            Spec.Http.observeRequests (post "http://fake-api.com/stuff")
              |> expect (
                isListWhere
                  [ Spec.Http.jsonBody (Json.field "name" Json.int) <| equals 31
                  ]
              )
          )
        ]
    )
  ]


queryParamsSpec : Spec Model Msg
queryParamsSpec =
  Spec.describe "query params"
  [ scenario "the request has a query string" (
      given (
        testSubject (getRequestWithQuery [ ("activity", "bowling") ]) []
      )
      |> whenTheRequestIsTriggered
      |> observeThat
        [ it "contains the expected query param" (
            Spec.Http.observeRequests (get "http://fake-api.com/stuff" |> withAnyQuery)
              |> expect (isListWhere
                [ Spec.Http.queryParameter "activity" <| isListWhere [ equals "bowling" ]
                ]
              )
          )
        , it "fails when the claim fails" (
            Spec.Http.observeRequests (get "http://fake-api.com/stuff" |> withAnyQuery)
              |> expect (isListWhere
                [ Spec.Http.queryParameter "activity" <| isListWhere [ equals "nothing" ]
                ]
              )
          )
        , it "does not find some param that's not there" (
            Spec.Http.observeRequests (get "http://fake-api.com/stuff" |> withAnyQuery)
              |> expect (isListWhere
                [ Spec.Http.queryParameter "unknown" <| isListWhere [ equals "something" ]
                ]
              )
          )
        , it "does not match with an exact query" (
            Spec.Http.observeRequests (get "http://fake-api.com/stuff?activity=running")
              |> expect (isListWithLength 1)
          )
        ]
    )
  , scenario "the request has no query string" (
      given (
        testSubject (getRequestWithQuery []) []
      )
      |> whenTheRequestIsTriggered
      |> observeThat
        [ it "does not observe any requests with a query" (
            Spec.Http.observeRequests (get "http://fake-api.com/stuff" |> withAnyQuery)
              |> expect (isListWithLength 0)
          )
        ]
    )
  ]


routeQuerySpec : Spec Model Msg
routeQuerySpec =
  Spec.describe "route query"
  [ scenario "match request with query when stub requests with any query" (
      given (
        testSubject (getRequestTo "http://fake-api.com/fun" [ ("activity", "running") ])
          [ successStubRoute (get "http://fake-api.com/fun" |> withAnyQuery) ]
      )
      |> whenTheRequestIsTriggered
      |> itReceivesTheStubbedResponse
    )
  , scenario "fail to match request without query when stub requests with any query" (
      given (
        testSubject (getRequestTo "http://fake-api.com/fun" [])
          [ successStubRoute (get "http://fake-api.com/fun" |> withAnyQuery) ]
      )
      |> whenTheRequestIsTriggered
      |> itDoesNotReceiveTheStubbResponse
    )
  , scenario "fail to match request with query when do not stub request with any query" (
      given (
        testSubject (getRequestTo "http://fake-api.com/fun" [ ("activity", "running") ])
          [ successStubRoute (get "http://fake-api.com/fun") ]
      )
      |> whenTheRequestIsTriggered
      |> itDoesNotReceiveTheStubbResponse
    )
  , scenario "matches request when stub specifies exact query" (
      given (
        testSubject (getRequestTo "http://fake-api.com/fun" [ ("activity", "running walking") ])
          [ successStubRoute (get "http://fake-api.com/fun?activity=running%20walking") ]
      )
      |> whenTheRequestIsTriggered
      |> itReceivesTheStubbedResponse
    )
  , scenario "ignores exact query when any query is specified" (
      given (
        testSubject (getRequestTo "http://fake-api.com/fun" [ ("activity", "running") ])
          [ successStubRoute (get "http://fake-api.com/fun?activity=walking" |> withAnyQuery) ]
      )
      |> whenTheRequestIsTriggered
      |> itReceivesTheStubbedResponse
    )
  ]


routeOriginSpec : Spec Model Msg
routeOriginSpec =
  Spec.describe "route path"
  [ scenario "matches request with no origin, just a path" (
      given (
        testSubject (getRequestTo "/some/awesome/path" [])
          [ successStubRoute (get "/some/awesome/path") ]
      )
      |> whenTheRequestIsTriggered
      |> observeThat
        [ itReceivesTheStubbedResponse
        , itObservesTheRequest (get "/some/awesome/path")
        ]
    )
  , scenario "does not match path that contains path at end" (
      given (
        testSubject (getRequestTo "/api/some/awesome/path" [])
          [ successStubRoute (get "/some/awesome/path") ]
      )
      |> whenTheRequestIsTriggered
      |> observeThat
        [ itDoesNotReceiveTheStubbResponse
        , itDoesNotObserveTheRequest (get "/some/awesome/path")
        ]
    )
  , scenario "does not match path that contains path at beginning" (
      given (
        testSubject (getRequestTo "/some/awesome/path/and/something" [])
          [ successStubRoute (get "/some/awesome/path") ]
      )
      |> whenTheRequestIsTriggered
      |> observeThat
        [ itDoesNotReceiveTheStubbResponse
        , itDoesNotObserveTheRequest (get "/some/awesome/path")
        ]
    )
  , scenario "fails to match request with path from any origin" (
      given (
        testSubject (getRequestTo "http://fake-api.com/some/awesome/path" [])
          [ successStubRoute (get "/some/awesome/path") ]
      )
      |> whenTheRequestIsTriggered
      |> observeThat
        [ itDoesNotReceiveTheStubbResponse
        , itDoesNotObserveTheRequest (get "/some/awesome/path")
        ]
    )
  , scenario "fails to match request to path when looking for any origin" (
      given (
        testSubject (getRequestTo "/some/awesome/path" [])
          [ successStubRoute (get "/some/awesome/path" |> withAnyOrigin) ]
      )
      |> whenTheRequestIsTriggered
      |> observeThat
        [ itDoesNotReceiveTheStubbResponse
        , itDoesNotObserveTheRequest (get "/some/awesome/path" |> withAnyOrigin)
        ]
    )
  , scenario "fails to match subset of path from any origin" (
      given (
        testSubject (getRequestTo "http://fake-api.com/some/cool/awesome/path" [])
          [ successStubRoute (get "/cool/awesome/path" |> withAnyOrigin) ]
      )
      |> whenTheRequestIsTriggered
      |> observeThat
        [ itDoesNotReceiveTheStubbResponse
        , itDoesNotObserveTheRequest (get "/cool/awesome/path" |> withAnyOrigin)
        ]
    )
  , scenario "matches request with path and query string from any origin" (
      given (
        testSubject (getRequestTo "http://fake.my-api.on_some_domain.com:9090/some/awesome/path" [ ("activity", "running") ])
          [ successStubRoute (get "/some/awesome/path?activity=running" |> withAnyOrigin) ]
      )
      |> whenTheRequestIsTriggered
      |> observeThat
        [ itReceivesTheStubbedResponse
        , itObservesTheRequest (get "/some/awesome/path?activity=running" |> withAnyOrigin)
        ]
    )
  , scenario "matches request with path and any query string from any origin" (
      given (
        testSubject (getRequestTo "http://fake-api.com/some/awesome/path" [ ("activity", "running") ])
          [ successStubRoute (get "/some/awesome/path" |> withAnyOrigin |> withAnyQuery) ]
      )
      |> whenTheRequestIsTriggered
      |> observeThat
        [ itReceivesTheStubbedResponse
        , itObservesTheRequest (get "/some/awesome/path" |> withAnyOrigin |> withAnyQuery)
        ]
    )
  , scenario "fails to observe request from any origin with wrong path" (
      given (
        testSubject (getRequestTo "http://fake-api.com/some/cool/path" []) []
      )
      |> whenTheRequestIsTriggered
      |> it "fails to observe a request" (
          Spec.Http.observeRequests (get "/some/awesome/path" |> withAnyOrigin)
            |> expect (isListWithLength 1)
      )
    )
  , scenario "overrides exact origin to match any" (
      given (
        testSubject (getRequestTo "http://fake-api.com/some/awesome/path" [ ("activity", "running") ])
          [ successStubRoute (get "http://some-other-place.com/some/awesome/path" |> withAnyOrigin |> withAnyQuery) ]
      )
      |> whenTheRequestIsTriggered
      |> observeThat
        [ itReceivesTheStubbedResponse
        , itObservesTheRequest (get "http://some-other-place.com/some/awesome/path" |> withAnyOrigin |> withAnyQuery)
        ]
    )
  ]


whenTheRequestIsTriggered =
  when "an http request is triggered"
    [ Markup.target << by [ id "trigger" ]
    , Event.click
    ]


getRequestWithQuery : List (String, String) -> Cmd Msg
getRequestWithQuery =
  getRequestTo "http://fake-api.com/stuff"


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


postRequestWithJson : Json.Value -> Cmd Msg
postRequestWithJson body =
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
  Setup.initWithModel defaultModel
    |> Setup.withView testView
    |> Setup.withUpdate (testUpdate doRequest)
    |> Stub.serve stubs


successStub =
  Stub.for (get "http://fake-api.com/stuff")
    |> Stub.withBody "{\"name\":\"Cool Dude\",\"score\":1034}"

successStubRoute route =
  Stub.for route
    |> Stub.withBody "{\"name\":\"Awesome Person\",\"score\":1944}"


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


otherSuccessStub =
  Stub.for (get "http://fake-api.com/fun")
    |> Stub.withBody "{\"name\":\"Fun Person\",\"score\":971}"

unauthorizedStub =
  Stub.for (get "http://fake-api.com/stuff")
    |> Stub.withStatus 401

type alias Model =
  { responses: List ResponseObject
  , error: Maybe Http.Error
  , requestStatus: String
  , metadata: Maybe Http.Metadata
  }

defaultModel =
  { responses = []
  , error = Nothing
  , requestStatus = "Idle"
  , metadata = Nothing
  }

type alias ResponseObject =
  { name: String
  , score: Int
  }

type Msg
  = MakeRequest
  | ReceivedResponse (Result Http.Error ResponseObject)
  | ReceivedMetadata (Result () Http.Metadata)

testView : Model -> Html Msg
testView model =
  Html.div []
  [ Html.button [ Attr.id "trigger", Events.onClick MakeRequest ]
    [ Html.text "Click to make request!" ]
  , Html.hr [] []
  , Html.div [ Attr.id "request-status" ] [ Html.text model.requestStatus ]
  ]

testUpdate : Cmd Msg -> Msg -> Model -> ( Model, Cmd Msg )
testUpdate doRequest msg model =
  case msg of
    MakeRequest ->
      ( { model | requestStatus = "In Progress" }, doRequest )
    ReceivedResponse response ->
      case response of
        Ok data ->
          ( { model | requestStatus = "Idle", responses = data :: model.responses, error = Nothing }, Cmd.none )
        Err err ->
          ( { model | requestStatus = "Idle", error = Just err }, Cmd.none )
    ReceivedMetadata response ->
      case response of
        Ok metadata ->
          ( { model | requestStatus = "Idle", metadata = Just metadata, error = Nothing }, Cmd.none )
        Err _ ->
          ( { model | requestStatus = "Idle", metadata = Nothing }, Cmd.none )

responseDecoder : Json.Decoder ResponseObject
responseDecoder =
  Json.map2 ResponseObject
    ( Json.field "name" Json.string )
    ( Json.field "score" Json.int )

selectSpec : String -> Maybe (Spec Model Msg)
selectSpec name =
  case name of
    "get" -> Just getSpec
    "abstain" -> Just abstainSpec
    "expectRequest" -> Just expectRequestSpec
    "hasHeader" -> Just hasHeaderSpec
    "hasBody" -> Just hasBodySpec
    "error" -> Just errorStubSpec
    "header" -> Just headerStubSpec
    "queryParams" -> Just queryParamsSpec
    "routeQuery" -> Just routeQuerySpec
    "routeOrigin" -> Just routeOriginSpec
    _ -> Nothing


main =
  Runner.browserProgram selectSpec