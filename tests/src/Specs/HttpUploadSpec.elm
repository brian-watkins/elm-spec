module Specs.HttpUploadSpec exposing (main)

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
import Spec.File
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Http
import Json.Decode as Json
import File exposing (File)
import File.Select
import Bytes exposing (Bytes)
import Bytes.Encode as Bytes
import Bytes.Decode as Decode
import Runner
import Specs.Helpers exposing (..)


uploadFileSpec : Spec Model Msg
uploadFileSpec =
  describe "upload file"
  [ scenario "POST file to server" (
      given (
        Setup.initWithModel testModel
          |> Setup.withView testView
          |> Setup.withUpdate testUpdate
          |> Stub.serve [ uploadStub ]
      )
      |> when "the file is selected"
        [ Markup.target << by [ id "select-file" ]
        , Event.click
        , Spec.File.select [ Spec.File.loadFrom "./fixtures/funFile.txt" ]
        ]
      |> when "the selected file is uploaded"
        [ Markup.target << by [ id "upload-to-server" ]
        , Event.click
        ]
      |> observeThat
        [ it "makes a request" (
            Spec.Http.observeRequests (post "http://fake-api.com/files")
              |> expect (isListWithLength 1)
          )
        , it "posts the correct file" (
            Spec.Http.observeRequests (post "http://fake-api.com/files")
              |> expect (isListWhere
                [ Spec.Http.fileBody <| require File.name <| 
                    normalizedPath >> isStringContaining 1 "tests/src/fixtures/funFile.txt"
                ]
              )
          )
        , it "fails when you make a false claim about the file" (
            Spec.Http.observeRequests (post "http://fake-api.com/files")
              |> expect (isListWhere
                [ Spec.Http.fileBody <| require File.name <| 
                    normalizedPath >> isStringContaining 1 "someOtherFile.png"
                ]
              )
          )
        , it "fails when you try to expect a string body" (
            Spec.Http.observeRequests (post "http://fake-api.com/files")
              |> expect (isListWhere
                [ Spec.Http.stringBody <| equals "blah"
                ]
              )
          )
        , it "fails when you try to expect a json body" (
            Spec.Http.observeRequests (post "http://fake-api.com/files")
              |> expect (isListWhere
                [ Spec.Http.jsonBody Json.string <| equals "blah"
                ]
              )
          )
        , it "fails when you try to expect bytes" (
            Spec.Http.observeRequests (post "http://fake-api.com/files")
              |> expect (isListWhere
                [ Spec.Http.bytesBody <| require Bytes.width <| equals 299
                ]
              )
          )
        ]
    )
  ]


uploadBytesSpec : Spec Model Msg
uploadBytesSpec =
  describe "upload bytes"
  [ scenario "POST bytes" (
      given (
        Setup.initWithModel { testModel | binaryText = "Some funny binary text!" }
          |> Setup.withView testView
          |> Setup.withUpdate testUpdate
          |> Stub.serve [ uploadStub ]
      )
      |> when "the bytes are posted"
        [ Markup.target << by [ id "send-bytes" ]
        , Event.click
        ]
      |> observeThat
        [ it "makes a request" (
            Spec.Http.observeRequests (post "http://fake-api.com/files")
              |> expect (isListWithLength 1)
          )
        , it "sends the expected bytes" (
            Spec.Http.observeRequests (post "http://fake-api.com/files")
              |> expect (isListWhere
                [ Spec.Http.bytesBody <|
                    (Decode.decode <| Decode.string 23) >> (isSomethingWhere <| equals "Some funny binary text!")
                ]
              )
          )
        , it "fails when you make a false claim about the bytes" (
            Spec.Http.observeRequests (post "http://fake-api.com/files")
              |> expect (isListWhere
                [ Spec.Http.bytesBody <| require Bytes.width <| equals 17
                ]
              )
          )
        , it "fails when you try to expect a file" (
            Spec.Http.observeRequests (post "http://fake-api.com/files")
              |> expect (isListWhere
                [ Spec.Http.fileBody <| require File.name <| equals "blah"
                ]
              )
          )
        , it "fails when you try to expect a string body" (
            Spec.Http.observeRequests (post "http://fake-api.com/files")
              |> expect (isListWhere
                [ Spec.Http.stringBody <| equals "blah"
                ]
              )
          )
        , it "fails when you try to expect a json body" (
            Spec.Http.observeRequests (post "http://fake-api.com/files")
              |> expect (isListWhere
                [ Spec.Http.jsonBody Json.string <| equals "blah"
                ]
              )
          )
        ]
    )
  ]


normalizedPath : String -> String
normalizedPath =
  String.replace ":" "/"


uploadStub =
  Stub.for (post "http://fake-api.com/files")
    |> Stub.abstain


type Msg
  = SelectFile
  | GotFile File
  | GotResponse (Result Http.Error String)
  | UploadFile
  | SendBytes


type alias Model =
  { selectedFile: Maybe File
  , binaryText: String
  }


testModel =
  { selectedFile = Nothing
  , binaryText = ""
  }


testView : Model -> Html Msg
testView model =
  Html.div []
  [ Html.button [ Attr.id "select-file", Events.onClick SelectFile ] [ Html.text "Select a file!" ]
  , Html.button [ Attr.id "upload-to-server", Events.onClick UploadFile ] [ Html.text "Upload file!" ]
  , Html.button [ Attr.id "send-bytes", Events.onClick SendBytes ] [ Html.text "Send Bytes!" ]
  ]


testUpdate : Msg -> Model -> ( Model, Cmd Msg )
testUpdate msg model =
  case msg of
    SelectFile ->
      ( model, File.Select.file [] GotFile )
    GotFile file ->
      ( { model | selectedFile = Just file }, Cmd.none )
    UploadFile ->
      ( model
      , Maybe.map postFile model.selectedFile
          |> Maybe.withDefault Cmd.none
      )
    SendBytes ->
      ( model, postBytes model.binaryText )
    GotResponse _ ->
      ( model, Cmd.none )


postFile : File -> Cmd Msg
postFile file =
  Http.post
    { url = "http://fake-api.com/files"
    , body = Http.fileBody file
    , expect = Http.expectString GotResponse
    }


postBytes : String -> Cmd Msg
postBytes text =
  Http.post
    { url = "http://fake-api.com/files"
    , body = Http.bytesBody "application/octet-stream" <| bytesFromString text
    , expect = Http.expectString GotResponse
    }


bytesFromString : String -> Bytes
bytesFromString =
  Bytes.encode << Bytes.string


selectSpec : String -> Maybe (Spec Model Msg)
selectSpec name =
  case name of
    "uploadFile" -> Just uploadFileSpec
    "uploadBytes" -> Just uploadBytesSpec
    _ -> Nothing


main =
  Runner.browserProgram selectSpec