module Specs.HttpLogSpec exposing (main)

import Spec exposing (..)
import Spec.Setup as Setup
import Spec.Markup as Markup
import Spec.Markup.Selector exposing (..)
import Spec.Markup.Event as Event
import Spec.Claim exposing (..)
import Spec.Http
import Spec.Http.Route exposing (..)
import Spec.File
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Http
import Bytes.Encode as Bytes
import File exposing (File)
import File.Select
import Json.Encode as Encode
import Runner


httpRequestLogSpec : Spec Model Msg
httpRequestLogSpec =
  Spec.describe "logRequests"
  [ scenario "there are requests" (
      given (
        testSubject
          [ getRequest "http://fun.com/fun/1" [ Http.header "Content-Type" "text/plain;charset=utf-8", Http.header "X-Fun-Header" "my-header" ]
          , getRequest "http://awesome.com/awesome?name=cool" [ Http.header "Content-Type" "text/plain;charset=utf-8" ]
          , postRequest "http://super.com/super"
          ]
      )
      |> when "requests are sent"
        [ Spec.Http.logRequests
        , Markup.target << by [ id "request-button" ]
        , Event.click
        , Spec.Http.logRequests
        , Event.click
        , Spec.Http.logRequests
        , Event.click
        , Spec.Http.logRequests
        ]
      |> observeThat
        [ it "makes the GET requests" (
            Spec.Http.observeRequests (route "GET" <| Matching ".+")
              |> expect (isListWithLength 2)
          )
        , it "makes the POST requests" (
            Spec.Http.observeRequests (route "POST" <| Matching ".+")
              |> expect (isListWithLength 1)
          )
        ]
    )
  ]

logBytesRequestSpec : Spec Model Msg
logBytesRequestSpec =
  describe "log an HTTP request with bytes body"
  [ scenario "the request is logged" (
      given (
        testSubject
          [ bytesRequest "http://fun.com/bytes" <| Bytes.encode <| Bytes.string "This is binary stuff!"
          ]
      )
      |> when "requests are sent"
        [ Markup.target << by [ id "request-button" ]
        , Event.click
        , Spec.Http.logRequests
        ]
      |> it "makes the POST requests" (
        Spec.Http.observeRequests (route "POST" <| Matching ".+")
          |> expect (isListWithLength 1)
      )
    )
  ]


logFileRequestSpec : Spec Model Msg
logFileRequestSpec =
  describe "log an HTTP request with file body"
  [ scenario "the request is logged" (
      given (
        testSubject
          [ fileRequest "http://fun.com/files"
          ]
      )
      |> when "a file is selected"
        [ Markup.target << by [ id "select-file" ]
        , Event.click
        , Spec.File.select
            [ Spec.File.withText "/some/path/to/my-test-file.txt" "some super cool content"
                |> Spec.File.withMimeType "text/plain"
            ]
        ]
      |> when "requests are sent"
        [ Markup.target << by [ id "request-button" ]
        , Event.click
        , Spec.Http.logRequests
        ]
      |> it "makes the POST requests" (
        Spec.Http.observeRequests (route "POST" <| Matching ".+")
          |> expect (isListWithLength 1)
      )
    )
  ]


getRequest url headers _ =
  Http.request
    { method = "GET"
    , headers = headers
    , url = url
    , body = Http.emptyBody
    , expect = Http.expectString ReceivedRequest
    , timeout = Nothing
    , tracker = Nothing
    }


postRequest url _ =
  Http.request
    { method = "POST"
    , headers =
      [ Http.header "Content-Type" "text/plain;charset=utf-8"
      , Http.header "X-Fun-Header" "my-header"
      , Http.header "X-Super-Header" "super"
      ]
    , url = url
    , body = Http.jsonBody <| Encode.object [ ("name", Encode.string "Cool Dude"), ( "count", Encode.int 27) ]
    , expect = Http.expectString ReceivedRequest
    , timeout = Nothing
    , tracker = Nothing
    }


bytesRequest url bytes _ =
  Http.post
    { url = url
    , body = Http.bytesBody "application/octet-stream" bytes
    , expect = Http.expectString ReceivedRequest
    }


fileRequest url (Model model) =
  model.selectedFile
    |> Maybe.map (\file ->
      Http.post
        { url = url
        , body = Http.fileBody file
        , expect = Http.expectString ReceivedRequest
        }
    )
    |> Maybe.withDefault Cmd.none


testSubject requests =
  Setup.initWithModel (defaultModel requests)
    |> Setup.withView testView
    |> Setup.withUpdate testUpdate


type Model =
  Model
    { requests: List (Model -> Cmd Msg)
    , selectedFile: Maybe File
    }


defaultModel requests =
  Model
    { requests = requests
    , selectedFile = Nothing
    }


type Msg
  = SendRequest
  | SelectFile
  | GotFile File
  | ReceivedRequest (Result Http.Error String)


testUpdate : Msg -> Model -> (Model, Cmd Msg)
testUpdate msg (Model model) =
  case msg of
    SelectFile ->
      ( Model model, File.Select.file [] GotFile )
    GotFile file ->
      ( Model { model | selectedFile = Just file }, Cmd.none )
    SendRequest ->
      case model.requests of
        [] ->
          ( Model model, Cmd.none )
        next :: requests ->
          ( Model { model | requests = requests }
          , next <| Model model
          )
    ReceivedRequest _ ->
      ( Model model, Cmd.none )


testView : Model -> Html Msg
testView model =
  Html.div []
  [ Html.button [ Attr.id "request-button", Events.onClick SendRequest ] [ Html.text "Send Next Request!" ]
  , Html.button [ Attr.id "select-file", Events.onClick SelectFile ] [ Html.text "Select file!" ]
  ]


selectSpec : String -> Maybe (Spec Model Msg)
selectSpec name =
  case name of
    "logRequests" -> Just httpRequestLogSpec
    "logBytesRequest" -> Just logBytesRequestSpec
    "logFileRequest" -> Just logFileRequestSpec
    _ -> Nothing


main =
  Runner.browserProgram selectSpec