module Specs.HttpValidationSpec exposing (main)

import Spec exposing (..)
import Spec.Setup as Setup
import Spec.Claim exposing (isSomethingWhere, isListWithLength)
import Spec.Markup as Markup
import Spec.Markup.Selector exposing (..)
import Spec.Markup.Event as Event
import Spec.Http
import Spec.Http.Route exposing (..)
import Spec.Http.Stub as Stub
import Specs.Helpers exposing (..)
import Http
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Json.Decode as Json
import Json.Encode as Encode
import Runner


openAPISpecScenarios : String -> String -> Spec Model Msg
openAPISpecScenarios label openApiSpecPath =
  describe ("Validate against " ++ label)
  [ scenario "A valid request is sent and valid response is returned" (
      given (
        validGetRequest
          |> testSetup 
          |> Stub.serve [ validResponse "Super cool!" ]
          |> Stub.validate openApiSpecPath
      )
      |> whenARequestIsSent
      |> observeThat
        [ it "recorded the request" (
            Spec.Http.observeRequests (get validGetUrl)
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
          |> Stub.serve [ validResponse "nothing" ]
          |> Stub.validate openApiSpecPath
      )
      |> whenARequestIsSent
      |> itShouldHaveFailedAlready
    )
    , scenario "A request with invalid value for required header is sent" (
      given (
        validGetRequest
          |> withHeaders [ Http.header "X-Fun-Times" "blah" ]
          |> testSetup
          |> Stub.serve [ validResponse "nothing" ]
          |> Stub.validate openApiSpecPath
      )
      |> whenARequestIsSent
      |> itShouldHaveFailedAlready
    )
  ]


testSetup requestCommand =
  Setup.initWithModel (defaultModel requestCommand)
    |> Setup.withView testView
    |> Setup.withUpdate testUpdate


whenARequestIsSent =
  when "a request is sent"
    [ Markup.target << by [ id "send-request-button" ]
    , Event.click
    ]


validResponse message =
  Stub.for (route "GET" <| Matching "http://fake-api.com/my/messages/.*")
    |> Stub.withBody (Stub.withJson <| Encode.object [ ("message", Encode.string message) ])


type alias Model =
  { request: RequestParams
  , message: String
  }

defaultModel requestParams =
  { request = requestParams
  , message = "Request not sent yet!"
  }


type Msg
  = SendRequest
  | ReceivedResponse (Result Http.Error String)


testView : Model -> Html Msg
testView model =
  Html.div []
  [ Html.button [ Attr.id "send-request-button", Events.onClick SendRequest ] [ Html.text "Send Request!" ]
  , Html.div [ Attr.id "response" ]
    [ Html.text model.message ]
  ]


testUpdate : Msg -> Model -> ( Model, Cmd Msg )
testUpdate msg model =
  let
    d = Debug.log "update" msg
  in
  case msg of
    SendRequest ->
      ( model
      , Http.request
          { method = model.request.method
          , headers =  model.request.headers
          , url = model.request.url
          , body = model.request.body
          , expect = Http.expectJson ReceivedResponse responseDecoder
          , timeout = Nothing
          , tracker = Nothing
          }
      )
    ReceivedResponse result ->
      case result of
        Ok message ->
          ( { model | message = message }, Cmd.none )
        Err _ ->
          ( { model | message = "ERROR" }, Cmd.none )


type alias RequestParams =
  { method: String
  , headers: List Http.Header
  , url: String
  , body: Http.Body
  }

validGetRequest : RequestParams
validGetRequest =
  { method = "GET"
  , headers =  [ Http.header "X-Fun-Times" "31" ]
  , url = validGetUrl
  , body = Http.emptyBody
  }

validGetUrl =
  "http://fake-api.com/my/messages/27"

withUrl : String -> RequestParams -> RequestParams
withUrl url params =
  { params | url = url }

withHeaders : List Http.Header -> RequestParams -> RequestParams
withHeaders headers params =
  { params | headers = headers }

responseDecoder : Json.Decoder String
responseDecoder =
  Json.field "message" Json.string


selectSpec : String -> Maybe (Spec Model Msg)
selectSpec name =
  case name of
    "validateOpenApi_v2" ->
      Just <| openAPISpecScenarios "OpenApi v2" "./fixtures/test-open-api-v2-spec.yaml"
    "validateOpenApi_v3" ->
      Just <| openAPISpecScenarios "OpenApi v3" "./fixtures/test-open-api-v3-spec.yaml"
    _ -> Nothing


main =
  Runner.browserProgram selectSpec