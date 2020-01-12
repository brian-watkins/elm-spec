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
  Spec.describe "route origin"
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
  , scenario "it matches an origin alone with trailing slash" (
      given (
        testSubject (getRequestTo "http://fun-town.com/" [])
          [ successStubRoute (get "http://fun-town.com") ]
      )
      |> whenTheRequestIsTriggered
      |> observeThat
        [ itReceivesTheStubbedResponse
        , itObservesTheRequest (get "http://fun-town.com")
        ]
    )
  , scenario "it matches an origin alone without a trailing slash" (
      given (
        testSubject (getRequestTo "http://fun-town.com" [])
          [ successStubRoute (get "http://fun-town.com/") ]
      )
      |> whenTheRequestIsTriggered
      |> observeThat
        [ itReceivesTheStubbedResponse
        , itObservesTheRequest (get "http://fun-town.com/")
        ]
    )
  , scenario "it does not match an origin alone when there is a path" (
      given (
        testSubject (getRequestTo "http://fun-town.com/" [])
          [ successStubRoute (get "http://fun-town.com/fun") ]
      )
      |> whenTheRequestIsTriggered
      |> observeThat
        [ itDoesNotReceiveTheStubbResponse
        , itDoesNotObserveTheRequest (get "http://fun-town.com/fun")
        ]
    )
  , scenario "dot in the last path component" (
      given (
        testSubject (getRequestTo "http://fun-town.com/funny/funngif" [])
          [ successStubRoute (get "http://fun-town.com/funny/fun.gif") ]
      )
      |> whenTheRequestIsTriggered
      |> observeThat
        [ itDoesNotReceiveTheStubbResponse
        , itDoesNotObserveTheRequest (get "http://fun-town.com/funny/fun.gif")
        ]
    )
  , scenario "dot in a middle path component" (
      given (
        testSubject (getRequestTo "http://fun-town.com/funny/things" [])
          [ successStubRoute (get "http://fun-town.com/fun.y/things") ]
      )
      |> whenTheRequestIsTriggered
      |> observeThat
        [ itDoesNotReceiveTheStubbResponse
        , itDoesNotObserveTheRequest (get "http://fun-town.com/fun.y/things")
        ]
    )
  ]


routePathSpec : Spec Model Msg
routePathSpec =
  Spec.describe "route path"
  [ scenario "claim about path variable is accepted" (
      given (
        testSubject (getRequestTo "http://fake-api.com/awesome/stuff/21/children" [])
          [ successStubRoute
            ( get "http://fake-api.com"
                |> withPath
                  [ Segment "awesome"
                  , Segment "stuff"
                  , Variable ""
                  , Segment "children"
                  ]
            )
          ]
      )
      |> whenTheRequestIsTriggered
      |> observeThat
        [ itReceivesTheStubbedResponse
        , it "accepts good claims about the path variable" (
            Spec.Http.observeRequests (
              get "http://fake-api.com"
                |> withPath
                  [ Segment "awesome"
                  , Segment "stuff"
                  , Variable "id"
                  , Segment "children"
                  ]
              )
              |> expect (isListWhere
                [ Spec.Http.pathVariable "id" <| equals "21"
                ]
              )
          )
        , it "rejects bad claims about the path variable" (
            Spec.Http.observeRequests (
              get "http://fake-api.com"
                |> withPath
                  [ Segment "awesome"
                  , Segment "stuff"
                  , Variable "id"
                  , Segment "children"
                  ]
              )
              |> expect (isListWhere
                [ Spec.Http.pathVariable "id" <| equals "nothing"
                ]
              )
          )
        , it "rejects the claim if the path variable is not found" (
            Spec.Http.observeRequests (
              get "http://fake-api.com"
                |> withPath
                  [ Segment "awesome"
                  , Segment "stuff"
                  , Variable "id"
                  , Segment "children"
                  ]
              )
              |> expect (isListWhere
                [ Spec.Http.pathVariable "something-else" <| equals "nothing"
                ]
              )
          )
        ]
    )
  , scenario "path variables with a query string" (
      given (
        testSubject (getRequestTo "http://fake-api.com/awesome/stuff/21/children" [ ("treat", "cake") ])
          [ successStubRoute
            ( get "http://fake-api.com"
                |> withPath
                  [ Segment "awesome"
                  , Segment "stuff"
                  , Variable "id"
                  , Segment "children"
                  ]
                |> withAnyQuery
            )
          ]
      )
      |> whenTheRequestIsTriggered
      |> observeThat
        [ itReceivesTheStubbedResponse
        , itObservesTheRequest (get "http://fake-api.com"
            |> withPath
              [ Segment "awesome"
              , Segment "stuff"
              , Variable "id"
              , Segment "children"
              ]
            |> withAnyQuery
          )
        ]
    )
  , scenario "request path has trailing slash" (
      given (
        testSubject (getRequestTo "http://fake-api.com/awesome/stuff/21/children/" [])
          [ successStubRoute
            ( get "http://fake-api.com"
                |> withPath
                  [ Segment "awesome"
                  , Segment "stuff"
                  , Variable "id"
                  , Segment "children"
                  ]
            )
          ]
      )
      |> whenTheRequestIsTriggered
      |> observeThat
        [ itReceivesTheStubbedResponse
        , itObservesTheRequest (get "http://fake-api.com"
            |> withPath
              [ Segment "awesome"
              , Segment "stuff"
              , Variable "id"
              , Segment "children"
              ]
          )
        ]
    )
  , scenario "path variable is at the end of the path and there is a trailing slash" (
      given (
        testSubject (getRequestTo "http://fake-api.com/awesome/stuff/21-things/" [])
          [ successStubRoute
            ( get "http://fake-api.com"
                |> withPath
                  [ Segment "awesome"
                  , Segment "stuff"
                  , Variable "id"
                  ]
            )
          ]
      )
      |> whenTheRequestIsTriggered
      |> observeThat
        [ itReceivesTheStubbedResponse
        , itObservesTheRequest (get "http://fake-api.com"
            |> withPath
              [ Segment "awesome"
              , Segment "stuff"
              , Variable "id"
              ]
          )
        ]
    )
  , scenario "path variable is at the end of the path and there is no trailing slash" (
      given (
        testSubject (getRequestTo "http://fake-api.com/awesome/stuff/21-things" [])
          [ successStubRoute
            ( get "http://fake-api.com"
                |> withPath
                  [ Segment "awesome"
                  , Segment "stuff"
                  , Variable "id"
                  ]
            )
          ]
      )
      |> whenTheRequestIsTriggered
      |> observeThat
        [ itReceivesTheStubbedResponse
        , itObservesTheRequest (get "http://fake-api.com"
            |> withPath
              [ Segment "awesome"
              , Segment "stuff"
              , Variable "id"
              ]
          )
        ]
    )
  , scenario "path variable is at the end of the path and there is a query" (
      given (
        testSubject (getRequestTo "http://fake-api.com/awesome/stuff/21-things" [ ("treat", "cake") ])
          [ successStubRoute
            ( get "http://fake-api.com"
                |> withPath
                  [ Segment "awesome"
                  , Segment "stuff"
                  , Variable "id"
                  ]
                |> withAnyQuery
            )
          ]
      )
      |> whenTheRequestIsTriggered
      |> observeThat
        [ itReceivesTheStubbedResponse
        , itObservesTheRequest (get "http://fake-api.com"
            |> withPath
              [ Segment "awesome"
              , Segment "stuff"
              , Variable "id"
              ]
            |> withAnyQuery
          )
        ]
    )
  ]


testSubject doRequest stubs =
  Setup.initWithModel defaultModel
    |> Setup.withView testView
    |> Setup.withUpdate (testUpdate doRequest)
    |> Stub.serve stubs


successStubRoute route =
  Stub.for route
    |> Stub.withBody "{\"name\":\"Awesome Person\",\"score\":1944}"


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
    "queryParams" -> Just queryParamsSpec
    "routeQuery" -> Just routeQuerySpec
    "routeOrigin" -> Just routeOriginSpec
    "routePath" -> Just routePathSpec
    _ -> Nothing


main =
  Runner.browserProgram selectSpec