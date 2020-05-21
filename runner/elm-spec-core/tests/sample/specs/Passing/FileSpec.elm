module Passing.FileSpec exposing (main)

import Spec exposing (..)
import Spec.Setup as Setup
import Spec.Markup as Markup
import Spec.Markup.Selector exposing (..)
import Spec.Markup.Event as Event
import Spec.Claim exposing (..)
import Spec.Observer as Observer
import Spec.Http.Stub as Stub
import Spec.Http.Route exposing (..)
import Spec.File
import Runner
import Main as App
import File


fileSpec =
  describe "uploading a file"
  [ scenario "the file exists" (
      given (
        Setup.initWithModel App.defaultModel
          |> Setup.withUpdate App.update
          |> Setup.withView App.view
      )
      |> when "a file is uploaded"
        [ Markup.target << by [ id "open-file-selector" ]
        , Event.click
        , Spec.File.select [ Spec.File.atPath "./specs/fixtures/file.txt" ]
        ]
      |> it "finds the file" (
        Observer.observeModel .uploadedFileContents
          |> expect (isSomethingWhere <| isEqual Debug.toString "This is such a fun file!")
      )
    )
  ]


downloadSpec =
  describe "dowloading a file"
  [ scenario "a text file" (
      given (
        Setup.initWithModel App.defaultModel
          |> Setup.withUpdate App.update
          |> Setup.withView App.view
          |> Stub.serve
            [ Stub.for (get "http://fake-fun.com/api/files/21")
                |> Stub.withBody (Stub.withTextAtPath "./specs/fixtures/awesome.txt")
            ]
      )
      |> when "a file is requested"
        [ Markup.target << by [ id "download-text" ]
        , Event.click
        ]
      |> it "downloads the file" (
        Observer.observeModel .downloadContents
          |> expect (isSomethingWhere <| isEqual Debug.toString "This is such an awesome file!")
      )
    )
  ]


main =
  Runner.program
    [ fileSpec
    , downloadSpec
    ]