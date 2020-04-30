module Spec.File exposing
  ( FileFixture
  , select
  , loadFrom
  , Download
  , observeDownloads
  , name
  , text
  )

{-| Observe and make claims about files during a spec.

# Select Files
@docs FileFixture, select, loadFrom

# Observe Downloaded Files
@docs Download, observeDownloads

# Make Claims about Downloaded Files
@docs name, text

-}

import Spec.Observer exposing (Observer)
import Spec.Observer.Internal as Observer
import Spec.Message as Message exposing (Message)
import Spec.Step as Step
import Spec.Step.Command as Command
import Spec.Claim as Claim exposing (Claim)
import Spec.Report as Report
import Json.Decode as Json
import Json.Encode as Encode


{-| Represents a file.
-}
type FileFixture
  = FileFixture FixtureData


type alias FixtureData =
  { path: String
  }


{-| A step that selects a file as input.

    Spec.when "a File is uploaded"
      [ Spec.Markup.target << by [ tag "input", attribute ("type", "file") ]
      , Spec.Markup.Event.click
      , Spec.File.select [ Spec.File.loadFrom "./fixtures/myFile.txt" ]
      ]

A previous step must open a file selector, either by clicking an input element of type `file` or
by taking some action that results in a `File.Select.file` command.

You may select multiple files.

The path to the file is relative to the current working directory of the elm-spec runner.

-}
select : List FileFixture -> Step.Context model -> Step.Command msg
select fixtures context =
  Message.for "_file" "fetch"
    |> Message.withBody (
      Encode.object
        [ ( "fileFixtures", Encode.list fileFixtureEncoder fixtures )
        ]
      )
    |> Command.sendRequest andThenSelectFile


fileFixtureEncoder : FileFixture -> Encode.Value
fileFixtureEncoder (FileFixture fixture) =
  Encode.object
    [ ("path", Encode.string fixture.path)
    ]


andThenSelectFile : Message -> Step.Command msg
andThenSelectFile message =
  case Message.decode Json.value message of
    Ok fileValues ->
      Message.for "_file" "select"
        |> Message.withBody (
          Encode.object
            [ ( "files", fileValues )
            ]
        )
        |> Command.sendMessage
    Err _ ->
      Command.nothing


{-| Create a FileFixture by loading a file from the local filesystem.

The path is typically relative to the current working directory of the elm-spec runner (but
check the docs for the runner you are using).
-}
loadFrom : String -> FileFixture
loadFrom path =
  FileFixture { path = path }


{-| Represents a file downloaded in the course of a scenario.
-}
type Download
  = Download DownloadData


type alias DownloadData =
  { name: String
  , content: String
  }


{-| Observe downloads tha occurred during a scenario.
-}
observeDownloads : Observer model (List Download)
observeDownloads =
  Observer.observeEffects <|
    \messages ->
      List.filter (Message.is "_file" "download") messages
        |> List.filterMap (Result.toMaybe << Message.decode downloadDecoder)


downloadDecoder : Json.Decoder Download
downloadDecoder =
  Json.map2 DownloadData
    (Json.field "name" Json.string)
    (Json.field "content" Json.string)
    |> Json.map Download


{-| Claim that the name of a downloaded file satisfies the given claim.

-}
name : Claim String -> Claim Download
name claim =
  \(Download download) ->
    claim download.name
      |> Claim.mapRejection (\report -> Report.batch
        [ Report.note "Claim rejected for downloaded file name"
        , report
        ]
      )


{-| Claim that the text content of a downloaded file satisfies the given claim.

-}
text : Claim String -> Claim Download
text claim =
  \(Download download) ->
    claim download.content
      |> Claim.mapRejection (\report -> Report.batch
        [ Report.note "Claim rejected for downloaded file text"
        , report
        ]
      )