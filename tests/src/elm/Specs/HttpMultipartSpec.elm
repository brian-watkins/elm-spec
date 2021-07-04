module Specs.HttpMultipartSpec exposing (main)

import Spec exposing (..)
import Spec.Setup as Setup
import Spec.Markup as Markup
import Spec.Claim exposing (..)
import Spec.Markup.Selector exposing (..)
import Spec.Markup.Event as Event
import Spec.Http
import Spec.Http.Route exposing (..)
import Spec.File
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Http
import File exposing (File)
import File.Select
import Bytes
import Bytes.Encode as Bytes
import Bytes.Decode as Decode
import Runner
import Specs.Helpers exposing (..)


multipartRequestSpec : Spec Model Msg
multipartRequestSpec =
  describe "multipart request"
  [ scenario "multipart request with file" (
      given (
        Setup.initWithModel testModel
          |> Setup.withUpdate testUpdate
          |> Setup.withView testView
      )
      |> when "a file is selected"
        [ Markup.target << by [ id "select-file" ]
        , Event.click
        , Spec.File.select [ Spec.File.withText "my-file.txt" "This is some really cool text!" ]
        ]
      |> when "the request is made"
        [ Markup.target << by [ id "send-request" ]
        , Event.click
        ]
      |> observeThat
        [ it "makes a request" (
            Spec.Http.observeRequests (post "http://fake.com/api/files")
              |> expect (isListWithLength 1)
          )
        , it "gets the name part" (
            Spec.Http.observeRequests (post "http://fake.com/api/files")
              |> expect (isListWhereItemAt 0 <|
                Spec.Http.bodyPart "my-name" Spec.Http.asText <| isListWhere
                  [ equals "Cool Dude"
                  ]
              )
          )
        , it "gets the file part" (
            Spec.Http.observeRequests (post "http://fake.com/api/files")
              |> expect (isListWhereItemAt 0 <|
                Spec.Http.bodyPart "my-file" Spec.Http.asFile <| isListWhere
                  [ specifyThat File.name <| equals "my-file.txt"
                  ]
              )
          )
        , it "gets the bytes part" (
            Spec.Http.observeRequests (post "http://fake.com/api/files")
              |> expect (isListWhereItemAt 0 <|
                Spec.Http.bodyPart "my-bytes" Spec.Http.asBlob <| isListWhere
                  [ specifyThat .data <|
                      (Decode.decode <| Decode.string 16) >> (isSomethingWhere <| equals "Some funny text!")
                  ]
              )
          )
        , it "gets the bytes mime type" (
            Spec.Http.observeRequests (post "http://fake.com/api/files")
              |> expect (isListWhereItemAt 0 <|
                Spec.Http.bodyPart "my-bytes" Spec.Http.asBlob <| isListWhere
                  [ specifyThat .mimeType <| equals "text/plain"
                  ]
              )
          )
        , it "fails when the claim fails" (
            Spec.Http.observeRequests (post "http://fake.com/api/files")
              |> expect (isListWhereItemAt 0 <|
                Spec.Http.bodyPart "my-name" Spec.Http.asText <| isListWhere
                  [ equals "Awesome Person"
                  ]
              )
          )
        , it "fails when the data has the wrong type" (
            Spec.Http.observeRequests (post "http://fake.com/api/files")
              |> expect (isListWhereItemAt 0 <|
                Spec.Http.bodyPart "my-name" Spec.Http.asFile <| isListWhere
                  [ specifyThat File.name <| equals "blah.txt"
                  ]
              )
          )
        , it "fails when there is no part with that name" (
            Spec.Http.observeRequests (post "http://fake.com/api/files")
              |> expect (isListWhereItemAt 0 <|
                Spec.Http.bodyPart "bad-name" Spec.Http.asText <| isListWhere
                  [ equals "blah"
                  ]
              )
          )
        , it "fails when try to treat the body as non-multipart" (
            Spec.Http.observeRequests (post "http://fake.com/api/files")
              |> expect (isListWhereItemAt 0 <|
                Spec.Http.body Spec.Http.asText <| equals "what??"
              )
          )
        ]
    )
  ]


type alias Model =
  { file: Maybe File
  }


testModel =
  { file = Nothing
  }


type Msg
  = SelectFile
  | GotFile File
  | SendRequest
  | GotResponse (Result Http.Error String)


testView : Model -> Html Msg
testView _ =
  Html.div []
  [ Html.button [ Attr.id "select-file", Events.onClick SelectFile ] [ Html.text "Select file" ]
  , Html.button [ Attr.id "send-request", Events.onClick SendRequest ] [ Html.text "Send File" ]
  ]


testUpdate : Msg -> Model -> ( Model, Cmd Msg )
testUpdate msg model =
  case msg of
    SelectFile ->
      ( model, File.Select.file [] GotFile )
    GotFile file ->
      ( { model | file = Just file }, Cmd.none )
    SendRequest ->
      ( model
      , model.file
          |> Maybe.map sendFile
          |> Maybe.withDefault Cmd.none
      )
    GotResponse _ ->
      ( model, Cmd.none )


sendFile : File -> Cmd Msg
sendFile file =
  Http.post
    { url = "http://fake.com/api/files"
    , body =
        Http.multipartBody
        [ Http.stringPart "my-name" "Cool Dude"
        , Http.filePart "my-file" file
        , Http.bytesPart "my-bytes" "text/plain" <| Bytes.encode <| Bytes.string "Some funny text!"
        ]
    , expect = Http.expectString GotResponse
    }


selectSpec : String -> Maybe (Spec Model Msg)
selectSpec name =
  case name of
    "multipart" -> Just multipartRequestSpec
    _ -> Nothing


main =
  Runner.browserProgram selectSpec