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


type alias Model =
  { selectedFile: Maybe File
  }


testModel =
  { selectedFile = Nothing
  }


testView : Model -> Html Msg
testView model =
  Html.div []
  [ Html.button [ Attr.id "select-file", Events.onClick SelectFile ] [ Html.text "Select a file!" ]
  , Html.button [ Attr.id "upload-to-server", Events.onClick UploadFile ] [ Html.text "Upload file!" ]
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
    GotResponse _ ->
      ( model, Cmd.none )


postFile : File -> Cmd Msg
postFile file =
  Http.post
    { url = "http://fake-api.com/files"
    , body = Http.fileBody file
    , expect = Http.expectString GotResponse
    }


selectSpec : String -> Maybe (Spec Model Msg)
selectSpec name =
  case name of
    "uploadFile" -> Just uploadFileSpec
    _ -> Nothing


main =
  Runner.browserProgram selectSpec