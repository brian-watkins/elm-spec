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
import Bytes
import File
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
        testSubject (\model -> Cmd.batch [ getRequest model, getOtherRequest model ]) [ successStub, otherSuccessStub ]
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


getRequest : Model -> Cmd Msg
getRequest =
  getRequestWithTimeout Nothing


getRequestWithTimeout : Maybe Float -> Model -> Cmd Msg
getRequestWithTimeout timeout _ =
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


getOtherRequest : Model -> Cmd Msg
getOtherRequest _ =
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
        , it "uses the route function as expected to match an exact route" (
            Spec.Http.observeRequests (route "GET" <| Exact "http://fake-api.com/stuff")
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


resetSpec : Spec Model Msg
resetSpec =
  Spec.describe "Reset the request history between scenarios"
  [ scenario "some requests are made" (
      given (
        testSubject getRequest [ successStub ]
      )
      |> when "http requests are triggered"
        [ Markup.target << by [ id "trigger" ]
        , Event.click
        , Event.click
        , Event.click
        ]
      |> it "expects the request" (
        Spec.Http.observeRequests (get "http://fake-api.com/stuff")
          |> expect (isListWithLength 3)
      )
    )
  , scenario "some other number of requests are made" (
      given (
        testSubject getRequest [ successStub ]
      )
      |> when "http requests are triggered"
        [ Markup.target << by [ id "trigger" ]
        , Event.click
        , Event.click
        ]
      |> it "expects the request" (
        Spec.Http.observeRequests (get "http://fake-api.com/stuff")
          |> expect (isListWithLength 2)
      )
    )
  , scenario "no requests are made (and no stubs served)" (
      given (
        Setup.initWithModel defaultModel
          |> Setup.withView testView
          |> Setup.withUpdate (testUpdate getRequest)
      )
      |> it "sees that no requests have been made" (
        Spec.Http.observeRequests (get "http://fake-api.com/stuff")
          |> expect (isListWithLength 0)
      )
    )
  ]


clearRequestHistorySpec : Spec Model Msg
clearRequestHistorySpec =
  Spec.describe "Clear request history"
  [ scenario "the request history is cleared" (
      given (
        testSubject (getRequestWithParam "fun") [ successStubWithParam "fun" ]
      )
      |> when "some requests are triggered"
        [ Markup.target << by [ id "value-input" ]
        , Event.input "football"
        , Markup.target << by [ id "trigger" ]
        , Event.click
        , Event.click
        , Event.click
        ]
      |> when "the requests are cleared"
        [ Spec.Http.clearRequestHistory
        ]
      |> when "more requests are made"
        [ Markup.target << by [ id "value-input" ]
        , Event.input "running"
        , Markup.target << by [ id "trigger" ]
        , Event.click
        ]
      |> observeThat
        [ it "observes only requests after clearing the history" (
            Spec.Http.observeRequests (route "GET" <| Matching "http\\:\\/\\/fake\\-api\\.com\\/stuff\\?fun\\=.+")
              |> expect (isListWithLength 1)
          )
        , it "does not clear the stub" (
            Observer.observeModel .responses
              |> expect ( isListWhere
                [ equals { name = "Cool Dude", score = 1034 }
                , equals { name = "Cool Dude", score = 1034 }
                , equals { name = "Cool Dude", score = 1034 }
                , equals { name = "Cool Dude", score = 1034 }
                ]
              )
          )
        ]
    )
  ]


nowServeSpec : Spec Model Msg
nowServeSpec =
  Spec.describe "nowServe new stubs"
  [ scenario "overwriting an existing stub" (
      given (
        testSubject getRequest [ someStub ("me", 2984) ]
      )
      |> when "some requests are triggered"
        [ Markup.target << by [ id "trigger" ]
        , Event.click
        , Event.click
        ]
      |> when "the stub is reset"
        [ Stub.nowServe [ someStub ("you", 2112) ]
        ]
      |> when "more requests are triggered"
        [ Markup.target << by [ id "trigger" ]
        , Event.click
        , Event.click
        ]
      |> observeThat
        [ it "records the requests" (
            Spec.Http.observeRequests (get "http://fake-api.com/stuff")
              |> expect (isListWithLength 4)
          )
        , it "records the various responses" (
            Observer.observeModel .responses
              |> expect (isListWhere
                [ equals { name = "you", score = 2112 }
                , equals { name = "you", score = 2112 }
                , equals { name = "me", score = 2984 }
                , equals { name = "me", score = 2984 }
                ]
              )
          )
        ]
    )
  ]


someStub (name, number) =
  Stub.for (get "http://fake-api.com/stuff")
    |> Stub.withBody ("{\"name\":\"" ++ name ++ "\",\"score\":" ++ String.fromInt number ++ "}")


successStubWithParam key =
  Stub.for (route "GET" <| Matching <| "http:\\/\\/fake\\-api\\.com\\/stuff\\?" ++ key ++ "=.+")
    |> Stub.withBody "{\"name\":\"Cool Dude\",\"score\":1034}"


getRequestWithParam : String -> Model -> Cmd Msg
getRequestWithParam key model =
  Http.request
    { method = "GET"
    , headers =
      [ Http.header "X-Fun-Header" "some-fun-value"
      , Http.header "X-Awesome-Header" "some-awesome-value"
      ]
    , url = "http://fake-api.com/stuff?" ++ key ++ "=" ++ model.value
    , body = Http.emptyBody
    , expect = Http.expectJson ReceivedResponse responseDecoder
    , timeout = Nothing
    , tracker = Nothing
    }


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
                  [ ("x-fun-header", "fun-value" )
                  , ("x-super-header", "super-value" )
                  , ("location", "http://fun-place.com/fun")
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


fancyRequest : Model -> Cmd Msg
fancyRequest _ =
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
              |> expect (isSomethingWhere <| Markup.text <| equals "In Progress")
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
        , it "fails to find a file body" (
            Spec.Http.observeRequests (get "http://fake-api.com/stuff")
              |> expect (
                isListWhere
                  [ Spec.Http.fileBody <| require File.name <| equals "some file that was not uploaded"
                  ]
              )
          )
        , it "fails to find a bytes body" (
            Spec.Http.observeRequests (get "http://fake-api.com/stuff")
              |> expect (
                isListWhere
                  [ Spec.Http.bytesBody <| require Bytes.width <| equals 11
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
        , it "fails when making a claim about a file" (
            Spec.Http.observeRequests (post "http://fake-api.com/stuff")
              |> expect (
                isListWhere
                  [ Spec.Http.fileBody <| require File.name <| equals "Some file"
                  ]
              )
          )
        , it "fails when making a claim about bytes" (
            Spec.Http.observeRequests (post "http://fake-api.com/stuff")
              |> expect (
                isListWhere
                  [ Spec.Http.bytesBody <| require Bytes.width <| equals 11
                  ]
              )
          )
        ]
    )
  ]


whenTheRequestIsTriggered =
  when "an http request is triggered"
    [ Markup.target << by [ id "trigger" ]
    , Event.click
    ]


postRequestWithJson : Json.Value -> Model -> Cmd Msg
postRequestWithJson body _ =
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

otherSuccessStub =
  Stub.for (get "http://fake-api.com/fun")
    |> Stub.withBody "{\"name\":\"Fun Person\",\"score\":971}"

unauthorizedStub =
  Stub.for (get "http://fake-api.com/stuff")
    |> Stub.withStatus 401

type alias Model =
  { value: String
  , responses: List ResponseObject
  , error: Maybe Http.Error
  , requestStatus: String
  , metadata: Maybe Http.Metadata
  }

defaultModel =
  { value = ""
  , responses = []
  , error = Nothing
  , requestStatus = "Idle"
  , metadata = Nothing
  }

type alias ResponseObject =
  { name: String
  , score: Int
  }

type Msg
  = ValueInput String
  | MakeRequest
  | ReceivedResponse (Result Http.Error ResponseObject)
  | ReceivedMetadata (Result () Http.Metadata)

testView : Model -> Html Msg
testView model =
  Html.div []
  [ Html.input [ Attr.id "value-input", Events.onInput ValueInput ] []
  , Html.button [ Attr.id "trigger", Events.onClick MakeRequest ]
    [ Html.text "Click to make request!" ]
  , Html.hr [] []
  , Html.div [ Attr.id "request-status" ] [ Html.text model.requestStatus ]
  ]

testUpdate : (Model -> Cmd Msg) -> Msg -> Model -> ( Model, Cmd Msg )
testUpdate doRequest msg model =
  case msg of
    ValueInput val ->
      ( { model | value = val }, Cmd.none )
    MakeRequest ->
      ( { model | requestStatus = "In Progress" }, doRequest model )
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
    "reset" -> Just resetSpec
    "clear" -> Just clearRequestHistorySpec
    "nowServe" -> Just nowServeSpec
    "hasHeader" -> Just hasHeaderSpec
    "hasBody" -> Just hasBodySpec
    "error" -> Just errorStubSpec
    "header" -> Just headerStubSpec
    _ -> Nothing


main =
  Runner.browserProgram selectSpec