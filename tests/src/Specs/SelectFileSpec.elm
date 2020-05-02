module Specs.SelectFileSpec exposing (main)

import Spec exposing (..)
import Spec.Setup as Setup
import Spec.Observer as Observer
import Spec.Claim exposing (isTrue, isStringContaining, isEqual, isListWhere, isListWhereItemAt)
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
        , Spec.File.select [ Spec.File.loadFrom "./fixtures/funFile.txt" ]
        ]
      |> observeThat
        [ it "processes a click event" (
            Observer.observeModel .clicks
              |> expect (equals 1)
          )
        , it "finds the file in the model" (
            Observer.observeModel .files
              |> expect (isListWhere
                [ normalizedPath >> isStringContaining 1 "tests/src/fixtures/funFile.txt"
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
        , Spec.File.select [ Spec.File.loadFrom "./fixtures/funFile.txt" ]
        ]
      |> it "finds the file in the model" (
        Observer.observeModel .files
          |> expect (isListWhere
            [ isTrue << String.endsWith "funFile.txt"
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
          [ Spec.File.loadFrom "./fixtures/funFile.txt"
          , Spec.File.loadFrom "./fixtures/awesomeFile.txt"
          ]
        ]
      |> observeThat
        [ it "finds the file name" (
            Observer.observeModel .files
              |> expect (isListWhere
                [ normalizedPath >> isStringContaining 1 "tests/src/fixtures/funFile.txt"
                , normalizedPath >> isStringContaining 1 "tests/src/fixtures/awesomeFile.txt"
                ]
              )
          )
        , it "finds the file content" (
            Observer.observeModel .fileContents
              |> expect (isListWhere
                [ equals "Here is text from a fun file!"
                , equals "Here is an awesome file, dude!"
                ]
              )
          ) 
        ]
    )
  ]

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
        [ Spec.File.select [ Spec.File.loadFrom "./fixtures/funFile.txt" ]
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
        [ Spec.File.select [ Spec.File.loadFrom "./fixtures/funFile.txt" ]
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
        , Spec.File.select [ Spec.File.loadFrom "non-existent-file.txt" ]
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

type alias Model =
  { files: List String
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
testView model =
  Html.div []
  [ Html.input 
    [ Attr.type_ "file"
    , Events.on "change" (Json.map GotFiles filesDecoder)
    , Events.onClick HandleClick
    ] []
  ]

testSelectView : Model -> Html Msg
testSelectView model =
  Html.div []
  [ Html.button [ Attr.id "select-file-button", Events.onClick SelectFile ] [ Html.text "Click to select a file!" ]
  ]


testSelectMultipleView : Model -> Html Msg
testSelectMultipleView model =
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
      ( { model | files = List.map File.name files }
      , List.map File.toString files
        |> Task.sequence
        |> Task.perform GotFileContents
      )
    GotFileContents fileContents ->
      ( { model | fileContents = fileContents }, Cmd.none )
    HandleClick ->
      ( { model | clicks = model.clicks + 1 }, Cmd.none )


selectSpec : String -> Maybe (Spec Model Msg)
selectSpec name =
  case name of
    "selectFile" -> Just selectFileSpec
    "noOpenSelector" -> Just noOpenSelectorSpec
    "noFileSelected" -> Just noFileSelectedSpec
    "badFile" -> Just noFileFetchedSpec
    _ -> Nothing


main =
  Runner.browserProgram selectSpec

