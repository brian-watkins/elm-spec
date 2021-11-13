module Specs.HttpValidationSpec exposing (main)

import Spec exposing (..)
import Spec.Setup as Setup
import Spec.Claim exposing (isSomethingWhere, isListWithLength)
import Spec.Markup as Markup
import Spec.Markup.Selector exposing (..)
import Spec.Markup.Event as Event
import Spec.Http
import Spec.Http.Route exposing (..)
import Spec.Http.Stub as Stub exposing (Contract)
import Specs.Helpers exposing (..)
import Http
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Json.Decode as Json
import Json.Encode as Encode
import Task
import Dict
import Runner
import Browser.Dom


openAPISpecScenarios : String -> Contract -> Spec Model Msg
openAPISpecScenarios label openApiContract =
  describe ("Validate against " ++ label)
  [ scenario "A valid request is sent and valid response is returned" (
      given (
        validGetRequest
          |> testSetup 
          |> Stub.serve
            [ validGetResponse "Super cool!" |> Stub.satisfies openApiContract ]
      )
      |> whenAGetRequestIsSent
      |> observeThat
        [ it "recorded the request" (
            Spec.Http.observeRequests (get <| validGetUrl ++ validQuery)
              |> expect (isListWithLength 1)
          )
        , it "handles the response" (
            Markup.observeElement
              |> Markup.query << by [ id "response" ]
              |> expect (isSomethingWhere <| Markup.text <| equals "Super cool!")
          )
        ]
    )
  , scenario "A request with invalid path param is sent" (
      given (
        validGetRequest
          |> withUrl "http://fake-api.com/my/messages/bad" 
          |> testSetup
          |> Stub.serve [ validGetResponse "nothing" |> Stub.satisfies openApiContract ]
      )
      |> whenAGetRequestIsSent
      |> itShouldHaveFailedAlready
    )
  , scenario "A request with invalid value for required header is sent" (
      given (
        validGetRequest
          |> withHeaders [ Http.header "X-Fun-Times" "blah" ]
          |> testSetup
          |> Stub.serve [ validGetResponse "nothing" |> Stub.satisfies openApiContract ]
      )
      |> whenAGetRequestIsSent
      |> itShouldHaveFailedAlready
    )
  , scenario "A request with invalid value for required query param is sent" (
      given (
        validGetRequest
          |> withQuery "?someValue=39"
          |> testSetup
          |> Stub.serve [ validGetResponse "nothing" |> Stub.satisfies openApiContract ]
      )
      |> whenAGetRequestIsSent
      |> itShouldHaveFailedAlready
    )
  , scenario "A request with multiple validation errors is sent" (
      given (
        validGetRequest
          |> withHeaders [ Http.header "X-Cool-Times" "blah" ]
          |> withQuery "?someValue=6"
          |> testSetup
          |> Stub.serve [ validGetResponse "nothing" |> Stub.satisfies openApiContract ]
      )
      |> whenAGetRequestIsSent
      |> itShouldHaveFailedAlready
    )
  , scenario "An invalid response is stubbed for a valid request" (
      given (
        validGetRequest
          |> testSetup
          |> Stub.serve [ invalidGetResponse |> Stub.satisfies openApiContract ]
      )
      |> whenAGetRequestIsSent
      |> itShouldHaveFailedAlready
    )
  , scenario "A request with valid request body is sent and valid response is received" (
      given (
        validPostRequest
          |> testSetup
          |> Stub.serve [ validPostResponse |> Stub.satisfies openApiContract ]
      )
      |> whenAPostRequestIsSent
      |> observeThat
        [ it "recorded the request" (
            Spec.Http.observeRequests (post <| validPostUrl)
              |> expect (isListWithLength 1)
          )
        , it "handles the response" (
            Markup.observeElement
              |> Markup.query << by [ id "post-response" ]
              |> expect (isSomethingWhere <| Markup.text <| equals "http://fake-api.com/my/messages/2")
          )
        ]
    )
  , scenario "A request with invalid request body is sent" (
      given (
        validPostRequest
          |> withBody invalidPostBody
          |> testSetup
          |> Stub.serve [ validPostResponse |> Stub.satisfies openApiContract ]
      )
      |> whenAPostRequestIsSent
      |> itShouldHaveFailedAlready
    )
  , scenario "A response with an invalid header is sent" (
      given (
        validPostRequest
          |> testSetup
          |> Stub.serve [ invalidPostResponse |> Stub.satisfies openApiContract ]
      )
      |> whenAPostRequestIsSent
      |> itShouldHaveFailedAlready
    )
  , scenario "A response with unknown status code is sent" (
      given (
        validPostRequest
          |> testSetup
          |> Stub.serve [ validPostResponse |> Stub.withStatus 500 |> Stub.satisfies openApiContract ]
      )
      |> whenAPostRequestIsSent
      |> itShouldHaveFailedAlready
    )
  , scenario "A request with undocumented path is sent" (
      given (
        unknownGetRequest
          |> testSetup
          |> Stub.serve [ unknownGetResponse |> Stub.satisfies openApiContract ]
      )
      |> whenAGetRequestIsSent
      |> itShouldHaveFailedAlready
    )
  , scenario "A request with undocumented method is sent" (
      given (
        unknownMethodRequest
          |> testSetup
          |> Stub.serve [ unknownMethodResponse |> Stub.satisfies openApiContract ]
      )
      |> whenAGetRequestIsSent
      |> itShouldHaveFailedAlready
    )
  , scenario "A request that expects text (not json) is sent" (
      given (
        validTextRequest
          |> testSetup
          |> Stub.serve [ validTextResponse "{blah => yikes!}" |> Stub.satisfies openApiContract ]
      )
      |> whenAGetRequestIsSent
      |> observeThat
        [ it "recorded the request" (
            Spec.Http.observeRequests (get validTextUrl)
              |> expect (isListWithLength 1)
          )
        , it "handles the response" (
            Markup.observeElement
              |> Markup.query << by [ id "response" ]
              |> expect (isSomethingWhere <| Markup.text <| equals "{blah => yikes!}")
          )
        ]
    )
  , scenario "a request that has the wrong body type (array instead of object)" (
      given (
        validPostRequest
          |> withBody (Http.jsonBody <| Encode.list identity [])
          |> testSetup
          |> Stub.serve [ validPostResponse |> Stub.satisfies openApiContract ]
      )
      |> whenAPostRequestIsSent
      |> itShouldHaveFailedAlready
    )
  , scenario "a response that has the wrong body type (array instead of object)" (
      given (
        validGetRequest
          |> testSetup
          |> Stub.serve [ arrayGetResponse |> Stub.satisfies openApiContract ]
      )
      |> whenAGetRequestIsSent
      |> itShouldHaveFailedAlready
    )
  , scenario "a response that fails while another command waiting on browser update is processing" (
      given (
        validGetRequest
          |> testSetup
          |> Stub.serve [ invalidGetResponse |> Stub.satisfies openApiContract ]
      )
      |> whenRequestAndScroll
      |> itShouldHaveFailedAlready
    )
  ]


resetStubsSpec : Spec Model Msg
resetStubsSpec =
  describe "Resetting stubs during a spec"
  [ scenario "nowServe is used to reset stubs" (
      given (
        validPostRequest
          |> withBody invalidPostBody
          |> testSetup
          |> Stub.serve [ validPostResponse ]
      )
      |> when "a contract is specified on new stubs"
        [ Stub.nowServe
          [ validPostResponse
              |> Stub.satisfies (Stub.openApiContractAt "./fixtures/test-open-api-v3-spec.yaml")
          ]
        ]
      |> whenAPostRequestIsSent
      |> itShouldHaveFailedAlready
    )
  ]


multipleContractsSpec : Spec Model Msg
multipleContractsSpec =
  describe "Multiple contracts"
  [ scenario "Requests to different endpoints each with their own contract" (
      given (
        Setup.initWithModel (defaultModel validGetRequest anotherValidGetRequest)
          |> Setup.withView testView
          |> Setup.withUpdate testUpdate
          |> Stub.serve
            [ validGetResponse "Very fun!"
                |> Stub.satisfies (Stub.openApiContractAt "./fixtures/test-open-api-v2-spec.yaml")
            , anotherValidGetResponse "Totally awesome!"
                |> Stub.satisfies (Stub.openApiContractAt "./fixtures/another-open-api-v3-spec.yaml")
            ]
      )
      |> whenAGetRequestIsSent
      |> whenAnotherGetRequestIsSent
      |> observeThat
        [ it "recorded the request" (
            Spec.Http.observeRequests (get <| validGetUrl ++ validQuery)
              |> expect (isListWithLength 1)
          )
        , it "recorded the other request" (
            Spec.Http.observeRequests (get anotherValidGetUrl)
              |> expect (isListWithLength 1)
          )
        , it "handles the response" (
            Markup.observeElement
              |> Markup.query << by [ id "response" ]
              |> expect (isSomethingWhere <| Markup.text <| equals "Very fun!")
          )
        , it "handles the other response" (
            Markup.observeElement
              |> Markup.query << by [ id "another-response" ]
              |> expect (isSomethingWhere <| Markup.text <| equals "Totally awesome!")
          )
        ]
    )
  ]

openApiErrorSpec : Spec Model Msg
openApiErrorSpec =
  describe "Errors with the OpenApi spec file"
  [ scenario "Bad path to OpenApi spec file" (
      given (
        validGetRequest
          |> testSetup
          |> Stub.serve 
            [ validGetResponse "hello"
                |> Stub.satisfies (Stub.openApiContractAt "./fixtures/aFileThatDoesNotExist.yaml")
            ]
      )
      |> itShouldHaveFailedAlready
    )
  , scenario "Bad YAML in OpenApi spec file" (
      given (
        validGetRequest
          |> testSetup
          |> Stub.serve
            [ validGetResponse "hello"
                |> Stub.satisfies (Stub.openApiContractAt "./fixtures/specWithBadYaml.yaml")
            ]
      )
      |> itShouldHaveFailedAlready
    )
  , scenario "Bad JSON in OpenApi spec file" (
      given (
        validGetRequest
          |> testSetup
          |> Stub.serve
            [ validGetResponse "hello"
                |> Stub.satisfies (Stub.openApiContractAt "./fixtures/specWithBadJson.txt")
            ]
      )
      |> itShouldHaveFailedAlready
    )
  , scenario "Invalid OpenApi document" (
      given (
        validGetRequest
          |> testSetup
          |> Stub.serve
            [ validGetResponse "hello"
                |> Stub.satisfies (Stub.openApiContractAt "./fixtures/badOpenApiSpec.yaml")
            ]
      )
      |> itShouldHaveFailedAlready
    )
  , scenario "Unknown OpenApi version" (
      given (
        validGetRequest
          |> testSetup
          |> Stub.serve
            [ validGetResponse "hello"
                |> Stub.satisfies (Stub.openApiContractAt "./fixtures/unknownVersionOpenApiSpec.yaml")
            ]
      )
      |> itShouldHaveFailedAlready
    )
  ]

testSetup requestCommand =
  Setup.initWithModel (defaultModel requestCommand requestCommand)
    |> Setup.withView testView
    |> Setup.withUpdate testUpdate


whenAGetRequestIsSent =
  when "a get request is sent"
    [ Markup.target << by [ id "request-message-button" ]
    , Event.click
    ]

whenRequestAndScroll =
  when "a get request is sent AND the browser scrolls"
    [ Markup.target << by [ id "request-and-scroll" ]
    , Event.click
    ]

whenAnotherGetRequestIsSent =
  when "another get request is sent"
    [ Markup.target << by [ id "another-request-button" ]
    , Event.click
    ]

whenAPostRequestIsSent =
  when "a post request is sent"
    [ Markup.target << by [ id "request-message-button" ]
    , Event.click
    ]


validGetResponse message =
  Stub.for (route "GET" <| Matching "http://fake-api.com/my/messages/.*")
    |> Stub.withBody (Stub.withJson <| Encode.object
      [ ("id", Encode.int 1)
      , ("message", Encode.string message)
      ]
    )

anotherValidGetResponse message =
  Stub.for (route "GET" <| Matching "http://another-api.com/api/words/.*")
    |> Stub.withBody (Stub.withJson <| Encode.object
      [ ("id", Encode.int 18)
      , ("message", Encode.string message)
      ]
    )

validTextResponse message =
  Stub.for (get "http://fake-api.com/my/text")
    |> Stub.withBody (Stub.withText message)

unknownGetResponse =
  Stub.for (route "GET" <| Matching "http://fake-api.com/some/unknown/path")

unknownMethodResponse =
  Stub.for (route "PATCH" <| Matching "http://fake-api.com/my/messages/.*")

invalidGetResponse =
  Stub.for (route "GET" <| Matching "http://fake-api.com/my/messages/.*")
    |> Stub.withBody (Stub.withJson <| Encode.object
      [ ("id", Encode.string "should be a number")
      , ("blerg", Encode.string "")
      ]
    )

arrayGetResponse =
  Stub.for (route "GET" <| Matching "http://fake-api.com/my/messages/.*")
    |> Stub.withBody (Stub.withJson <| Encode.list identity [])

validPostResponse =
  Stub.for (post "http://fake-api.com/my/messages")
    |> Stub.withHeader ( "Location", "http://fake-api.com/my/messages/2" )
    |> Stub.withHeader ( "X-Fun-Times", "27" )
    |> Stub.withStatus 201


invalidPostResponse =
  Stub.for (post "http://fake-api.com/my/messages")
    |> Stub.withHeader ( "Location", "" )
    |> Stub.withHeader ( "X-Fun-Times", "blerg" )
    |> Stub.withStatus 201


type alias Model =
  { request: RequestParams
  , anotherRequest: RequestParams
  , message: String
  , anotherMessage: String
  , location: String
  }

defaultModel requestParams anotherRequestParams =
  { request = requestParams
  , anotherRequest = anotherRequestParams
  , message = "Request not sent yet!"
  , anotherMessage = "Another request not sent yet!"
  , location = "Unknown"
  }


type Msg
  = RequestMessage
  | RequestAndScroll
  | RequestAnotherMessage
  | GotMessage (Result Http.Error String)
  | GotAnotherMessage (Result Http.Error String)
  | CreatedMessage (Result () String)
  | DoNothing


testView : Model -> Html Msg
testView model =
  Html.div []
  [ Html.button [ Attr.id "request-message-button", Events.onClick RequestMessage ]
      [ Html.text "Request message!" ]
  , Html.button [ Attr.id "request-and-scroll", Events.onClick RequestAndScroll ]
      [ Html.text "Request and Scroll!" ]
  , Html.div [ Attr.id "response" ]
    [ Html.text model.message ]
  , Html.div [ Attr.id "post-response" ]
    [ Html.text model.location ]
  , Html.button [ Attr.id "another-request-button", Events.onClick RequestAnotherMessage ] [ Html.text "Request another message!" ]
  , Html.div [ Attr.id "another-response" ]
    [ Html.text model.anotherMessage ]
  ]


testUpdate : Msg -> Model -> ( Model, Cmd Msg )
testUpdate msg model =
  case msg of
    RequestMessage ->
      ( model
      , makeRequest model.request
      )
    RequestAnotherMessage ->
      ( model
      , makeRequest model.anotherRequest
      )
    RequestAndScroll ->
      ( model
      , Cmd.batch
        [ makeRequest model.request
        , Browser.Dom.setViewport 0 0
            |> Task.perform (always DoNothing)
        ]
      )
    GotMessage result ->
      case result of
        Ok message ->
          ( { model | message = message }, Cmd.none )
        Err _ ->
          ( { model | message = "ERROR" }, Cmd.none )
    GotAnotherMessage result ->
      case result of
        Ok message ->
          ( { model | anotherMessage = message }, Cmd.none )
        Err _ ->
          ( { model | anotherMessage = "ERROR" }, Cmd.none )
    CreatedMessage result ->
      case result of
        Ok location ->
          ( { model | location = location }, Cmd.none )
        Err _ ->
          ( { model | location = "ERROR" }, Cmd.none )
    DoNothing ->
      ( model, Cmd.none )

makeRequest : RequestParams -> Cmd Msg
makeRequest params =
  Http.request
    { method = params.method
    , headers =  params.headers
    , url = params.url ++ params.query
    , body = params.body
    , expect = params.expect
    , timeout = Nothing
    , tracker = Nothing
    }

getLocationHeader : Http.Response String -> Result () String
getLocationHeader response =
  case response of
    Http.GoodStatus_ metadata _ ->
      Dict.get "location" metadata.headers
        |> Maybe.withDefault "No Location Specified"
        |> Ok
    _ ->
      Err ()


type alias RequestParams =
  { method: String
  , headers: List Http.Header
  , url: String
  , query: String
  , body: Http.Body
  , expect: Http.Expect Msg
  }

unknownGetRequest : RequestParams
unknownGetRequest =
  { method = "GET"
  , headers = []
  , url = "http://fake-api.com/some/unknown/path"
  , query = ""
  , body = Http.emptyBody
  , expect = Http.expectJson GotMessage responseDecoder
  }

unknownMethodRequest : RequestParams
unknownMethodRequest =
  { method = "PATCH"
  , headers = []
  , url = "http://fake-api.com/my/messages/18"
  , query = ""
  , body = Http.emptyBody
  , expect = Http.expectJson GotMessage responseDecoder
  }

validGetRequest : RequestParams
validGetRequest =
  { method = "GET"
  , headers = [ Http.header "X-Fun-Times" "31" ]
  , url = validGetUrl
  , query = validQuery
  , body = Http.emptyBody
  , expect = Http.expectJson GotMessage responseDecoder
  }

validTextRequest : RequestParams
validTextRequest =
  { method = "GET"
  , headers = []
  , url = validTextUrl
  , query = ""
  , body = Http.emptyBody
  , expect = Http.expectString GotMessage
  }

validTextUrl =
  "http://fake-api.com/my/text"

anotherValidGetRequest : RequestParams
anotherValidGetRequest =
  { method = "GET"
  , headers = []
  , url = anotherValidGetUrl
  , query = ""
  , body = Http.emptyBody
  , expect = Http.expectJson GotAnotherMessage responseDecoder
  }


validGetUrl =
  "http://fake-api.com/my/messages/27"


anotherValidGetUrl =
  "http://another-api.com/api/words/18"


validQuery =
  "?someValue=12"


validPostRequest : RequestParams
validPostRequest =
  { method = "POST"
  , headers = []
  , url = validPostUrl
  , query = ""
  , body = validPostBody
  , expect = Http.expectStringResponse CreatedMessage getLocationHeader
  }


validPostUrl =
  "http://fake-api.com/my/messages"


validPostBody : Http.Body
validPostBody =
  Http.jsonBody <| Encode.object
    [ ( "message", Encode.string "A new cool message!" )
    ]


invalidPostBody : Http.Body
invalidPostBody =
  Http.jsonBody <| Encode.object
    [ ("blerg", Encode.int 17)
    ]


withUrl : String -> RequestParams -> RequestParams
withUrl url params =
  { params | url = url }

withHeaders : List Http.Header -> RequestParams -> RequestParams
withHeaders headers params =
  { params | headers = headers }

withQuery : String -> RequestParams -> RequestParams
withQuery query params =
  { params | query = query }

withBody : Http.Body -> RequestParams -> RequestParams
withBody body params =
  { params | body = body }

responseDecoder : Json.Decoder String
responseDecoder =
  Json.field "message" Json.string


selectSpec : String -> Maybe (Spec Model Msg)
selectSpec name =
  case name of
    "validateOpenApi_v2_yaml" ->
      Just <| openAPISpecScenarios "OpenApi v2" <| Stub.openApiContractAt "./fixtures/test-open-api-v2-spec.yaml"
    "validateOpenApi_v3_yaml" ->
      Just <| openAPISpecScenarios "OpenApi v3" <| Stub.openApiContractAt "./fixtures/test-open-api-v3-spec.yaml"
    "validateOpenApi_v2_json" ->
      Just <| openAPISpecScenarios "OpenApi v2" <| Stub.openApiContractAt "./fixtures/test-open-api-v2-spec.json"
    "validateOpenApi_v3_json" ->
      Just <| openAPISpecScenarios "OpenApi v3" <| Stub.openApiContractAt "./fixtures/test-open-api-v3-spec.json"
    "openApiErrors" ->
      Just openApiErrorSpec
    "multipleContracts" ->
      Just multipleContractsSpec
    "resetStubs" ->
      Just resetStubsSpec
    _ -> Nothing


main =
  Runner.browserProgram selectSpec