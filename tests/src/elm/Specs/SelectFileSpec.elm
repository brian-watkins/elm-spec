module Specs.SelectFileSpec exposing (main)

import Spec exposing (..)
import Spec.Setup as Setup
import Spec.Observer as Observer
import Spec.Claim exposing (..)
import Spec.Markup as Markup
import Spec.Markup.Selector exposing (..)
import Spec.Markup.Event as Event
import Spec.File
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Json.Decode as Json
import File exposing (File)
import File.Select
import Task
import Time
import Bytes exposing (Bytes)
import Bytes.Encode as Bytes
import Runner
import Specs.Helpers exposing (..)


selectFileSpec : Spec Model Msg
selectFileSpec =
  describe "file select"
  [ scenario "selecting a single file with input element" (
      given (
        Setup.initWithModel testModel
          |> Setup.withView testView
          |> Setup.withUpdate testUpdate
      )
      |> when "selecting a new file"
        [ Markup.target << by [ tag "input", attribute ("type", "file") ]
        , Event.click
        , Spec.File.select [ Spec.File.atPath "./fixtures/funFile.txt" ]
        ]
      |> observeThat
        [ it "processes a click event" (
            Observer.observeModel .clicks
              |> expect (equals 1)
          )
        , it "finds the file in the model" (
            Observer.observeModel .files
              |> expect (isListWhere
                [ File.name >> normalizedPath >> isStringContaining 1 "tests/fixtures/funFile.txt"
                ]
              )
          )
        , it "uploads the expected file from disk" (
            Observer.observeModel .fileContents
              |> expect (isListWhereItemAt 0 <| equals "Here is text from a fun file!")
          )
        ]
    )
  , scenario "selecting a single file with File.Select" (
      given (
        Setup.initWithModel testModel
          |> Setup.withView testSelectView
          |> Setup.withUpdate testUpdate
      )
      |> when "selecting a new file"
        [ Markup.target << by [ id "select-file-button" ]
        , Event.click
        , Spec.File.select [ Spec.File.atPath "./fixtures/funFile.txt" ]
        ]
      |> it "finds the file in the model" (
        Observer.observeModel .files
          |> expect (isListWhere
            [ File.name >> String.endsWith "funFile.txt" >> isTrue
            ]
          )
      )
    )
  , scenario "select multiple files with File.Select" (
      given (
        Setup.initWithModel testModel
          |> Setup.withView testSelectMultipleView
          |> Setup.withUpdate testUpdate
      )
      |> when "selecting multiple files"
        [ Markup.target << by [ id "select-files-button" ]
        , Event.click
        , Spec.File.select
          [ Spec.File.atPath "./fixtures/funFile.txt"
          , Spec.File.atPath "./fixtures/awesomeFile.txt"
          ]
        ]
      |> observeThat
        [ it "finds the file name" (
            Observer.observeModel .files
              |> expect (isListWhere
                [ File.name >> normalizedPath >> isStringContaining 1 "tests/fixtures/funFile.txt"
                , File.name >> normalizedPath >> isStringContaining 1 "tests/fixtures/awesomeFile.txt"
                ]
              )
          )
        , it "finds the file content" (
            Observer.observeModel .fileContents
              |> expect (isListWhere
                [ equals "Here is text from a fun file!"
                , isStringContaining 1 "And that was some awesome stuff!"
                ]
              )
          ) 
        ]
    )
  , scenario "select multiple fake files" (
      given (
        Setup.initWithModel testModel
          |> Setup.withView testSelectMultipleView
          |> Setup.withUpdate testUpdate
      )
      |> when "selecting multiple files"
        [ Markup.target << by [ id "select-files-button" ]
        , Event.click
        , Spec.File.select
          [ Spec.File.withBytes "/fun/path/to/funFile.txt" <| bytesFromString "This is a cool file!"
          , Spec.File.withBytes "awesomeFile.png" <| bytesFromString "Another awesome file!"
          , Spec.File.withText "/my/path/to/a/superFile.txt" "This is the best file ever!"
          , Spec.File.withText "nice-file.txt" "This file is also nice!"
          ]
        ]
      |> observeThat
        [ it "finds the file name" (
            Observer.observeModel .files
              |> expect (isListWhere
                [ File.name >> normalizedPath >> equals "/fun/path/to/funFile.txt"
                , File.name >> equals "awesomeFile.png"
                , File.name >> normalizedPath >> equals "/my/path/to/a/superFile.txt"
                , File.name >> equals "nice-file.txt"
                ]
              )
          )
        , it "finds the file content" (
            Observer.observeModel .fileContents
              |> expect (isListWhere
                [ equals "This is a cool file!"
                , equals "Another awesome file!"
                , equals "This is the best file ever!"
                , equals "This file is also nice!"
                ]
              )
          )
        ]
    )
  ]


multipleActionsSpec : Spec Model Msg
multipleActionsSpec =
  describe "other updates happening alongside file read"
  [ scenario "reading text of a file" (
      given (
        Setup.initWithModel testModel
          |> Setup.withView testSelectView
          |> Setup.withUpdate testUpdate
      )
      |> when "selecting a new file"
        [ Markup.target << by [ id "select-file-button" ]
        , Event.click
        , Spec.File.select [ Spec.File.atPath "./fixtures/funFile.txt" ]
        , Markup.target << by [ id "read-text-and" ]
        , Event.click
        ]
      |> observeThat
        [ it "records another click" (
            Observer.observeModel .clicks
              |> expect (equals 1)
          )
        , it "reads the text" (
            Observer.observeModel .fileContents
              |> expect (isListWhereItemAt 0 <| equals "Extra: Here is text from a fun file!")
          )
        ]
    )
  ]


mimeTypeSpec : Spec Model Msg
mimeTypeSpec =
  describe "setting the mime type of a file"
  [ scenario "fake files" (
      given (
        Setup.initWithModel testModel
          |> Setup.withView testSelectMultipleView
          |> Setup.withUpdate testUpdate
      )
      |> when "selecting a new file"
        [ Markup.target << by [ id "select-files-button" ]
        , Event.click
        , Spec.File.select
          [ Spec.File.atPath "./fixtures/funFile.txt"
              |> Spec.File.withMimeType "text/plain"
          , Spec.File.atPath "./fixtures/funFile.txt"
          , Spec.File.withText "super-file.txt" "Some funny text for a file!"
              |> Spec.File.withMimeType "text/fun"
          , Spec.File.withText "another-file.txt" "Another funny file!"
          , bytesFromString "This is a cool file!"
              |> Spec.File.withBytes "/fun/path/to/funFile.txt"
              |> Spec.File.withMimeType "application/bytes"
          , bytesFromString "This is a super cool file!"
              |> Spec.File.withBytes "/fun/path/to/coolFile.txt"
          ]
        ]
      |> it "finds the files have the expected mime type" (
        Observer.observeModel .files
          |> expect (isListWhere
            [ specifyThat File.mime <| equals "text/plain"
            , specifyThat File.mime <| equals ""
            , specifyThat File.mime <| equals "text/fun"
            , specifyThat File.mime <| equals ""
            , specifyThat File.mime <| equals "application/bytes"
            , specifyThat File.mime <| equals ""
            ]
          )
      )
    )
  ]


lastModifiedSpec : Spec Model Msg
lastModifiedSpec =
  describe "setting the last modified date of a file"
  [ scenario "fake files" (
      given (
        Setup.initWithModel testModel
          |> Setup.withView testSelectMultipleView
          |> Setup.withUpdate testUpdate
      )
      |> when "selecting a new file"
        [ Markup.target << by [ id "select-files-button" ]
        , Event.click
        , Spec.File.select
          [ Spec.File.atPath "./fixtures/funFile.txt"
              |> Spec.File.withLastModified 1589132162579
          , Spec.File.atPath "./fixtures/funFile.txt"
          , Spec.File.withText "super-file.txt" "Some funny text for a file!"
              |> Spec.File.withLastModified 1589132162577
          , Spec.File.withText "another-file.txt" "Another funny file!"
          , bytesFromString "This is a cool file!"
              |> Spec.File.withBytes "/fun/path/to/funFile.txt"
              |> Spec.File.withLastModified 1589132162575
          , bytesFromString "This is a super cool file!"
              |> Spec.File.withBytes "/fun/path/to/coolFile.txt"
          ]
        ]
      |> it "finds the files have the expected last modified date" (
        Observer.observeModel .files
          |> expect (isListWhere
            [ File.lastModified >> Time.posixToMillis >> equals 1589132162579
            , File.lastModified >> Time.posixToMillis >> (<) 1589132162579 >> isTrue
            , File.lastModified >> Time.posixToMillis >> equals 1589132162577
            , File.lastModified >> Time.posixToMillis >> (<) 1589132162579 >> isTrue
            , File.lastModified >> Time.posixToMillis >> equals 1589132162575
            , File.lastModified >> Time.posixToMillis >> (<) 1589132162579 >> isTrue
            ]
          )
      )
    )
  ]


bytesFromString : String -> Bytes
bytesFromString =
  Bytes.encode << Bytes.string


normalizedPath : String -> String
normalizedPath =
  String.replace ":" "/"

noOpenSelectorSpec : Spec Model Msg
noOpenSelectorSpec =
  describe "selecting a file with no open selector"
  [ scenario "no file input has been opened" (
      given (
        Setup.initWithModel testModel
          |> Setup.withView testView
          |> Setup.withUpdate testUpdate
      )
      |> when "selecting a file without selecting a file input"
        [ Spec.File.select [ Spec.File.atPath "./fixtures/funFile.txt" ]
        ]
      |> itShouldHaveFailedAlready
    )
  ]


noFileSelectedSpec : Spec Model Msg
noFileSelectedSpec =
  describe "resetting the file selector"
  [ scenario "no file is selected but the selector is open" (
      given (
        Setup.initWithModel testModel
          |> Setup.withView testSelectView
          |> Setup.withUpdate testUpdate
      )
      |> when "the selector is opened"
        [ Markup.target << by [ id "select-file-button" ]
        , Event.click
        ]
      |> it "has not uploaded any file" (
        Observer.observeModel .files
          |> expect (equals [])
      )
    )
  , scenario "no file input has been opened" (
      given (
        Setup.initWithModel testModel
          |> Setup.withView testView
          |> Setup.withUpdate testUpdate
      )
      |> when "selecting a file without selecting a file input"
        [ Spec.File.select [ Spec.File.atPath "./fixtures/funFile.txt" ]
        ]
      |> itShouldHaveFailedAlready
    )
  ]


noFileFetchedSpec : Spec Model Msg
noFileFetchedSpec =
  describe "error when fetching file to upload"
  [ scenario "selected file doesn't exist" (
      given (
        Setup.initWithModel testModel
          |> Setup.withView testView
          |> Setup.withUpdate testUpdate
      )
      |> when "a non-existent file is selected"
        [ Markup.target << by [ tag "input" ]
        , Event.click
        , Spec.File.select [ Spec.File.atPath "non-existent-file.txt" ]
        , Event.click
        , Event.click
        , Event.click
        ]
      |> itShouldHaveFailedAlready
    )
  ]


type Msg
  = GotFiles (List File)
  | GotMultipleFiles File (List File)
  | GotFileContents (List String)
  | SelectFile
  | SelectFiles
  | HandleClick
  | HandleRead

type alias Model =
  { files: List File
  , fileContents: List String
  , clicks: Int
  }

testModel : Model
testModel =
  { files = []
  , fileContents = []
  , clicks = 0
  }

testView : Model -> Html Msg
testView _ =
  Html.div []
  [ Html.input 
    [ Attr.type_ "file"
    , Events.on "change" (Json.map GotFiles filesDecoder)
    , Events.onClick HandleClick
    ] []
  ]

testSelectView : Model -> Html Msg
testSelectView _ =
  Html.div []
  [ Html.button [ Attr.id "select-file-button", Events.onClick SelectFile ] [ Html.text "Click to select a file!" ]
  , Html.button [ Attr.id "read-text-and", Events.onMouseDown HandleRead, Events.onClick HandleClick ]
    [ Html.text "Read Text and Do Other Things" ]
  ]


testSelectMultipleView : Model -> Html Msg
testSelectMultipleView _ =
  Html.div []
  [ Html.button [ Attr.id "select-files-button", Events.onClick SelectFiles ] [ Html.text "Click to select some files!" ]
  ]


filesDecoder : Json.Decoder (List File)
filesDecoder =
  Json.at [ "target", "files" ] (Json.list File.decoder)


testUpdate : Msg -> Model -> (Model, Cmd Msg)
testUpdate msg model =
  case msg of
    SelectFile ->
      ( model, File.Select.file [] <| \file -> GotFiles [ file ] )
    SelectFiles ->
      ( model, File.Select.files [] GotMultipleFiles )
    GotMultipleFiles file remaining ->
      ( model
      , file :: remaining
        |> Task.succeed
        |> Task.perform GotFiles
      )
    GotFiles files ->
      ( { model | files = files }
      , List.map File.toString files
        |> Task.sequence
        |> Task.perform GotFileContents
      )
    GotFileContents fileContents ->
      ( { model | fileContents = fileContents }, Cmd.none )
    HandleClick ->
      ( { model | clicks = model.clicks + 1 }, Cmd.none )
    HandleRead ->
      ( model
      , List.map File.toString model.files
          |> Task.sequence
          |> Task.map (List.map (\text -> "Extra: " ++ text))
          |> Task.perform GotFileContents
      )


selectSpec : String -> Maybe (Spec Model Msg)
selectSpec name =
  case name of
    "selectFile" -> Just selectFileSpec
    "noOpenSelector" -> Just noOpenSelectorSpec
    "noFileSelected" -> Just noFileSelectedSpec
    "badFile" -> Just noFileFetchedSpec
    "lastModified" -> Just lastModifiedSpec
    "mimeType" -> Just mimeTypeSpec
    "multipleActions" -> Just multipleActionsSpec
    _ -> Nothing


main =
  Runner.browserProgram selectSpec

