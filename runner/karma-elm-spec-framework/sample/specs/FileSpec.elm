module FileSpec exposing (main)

import Spec exposing (..)
import Spec.Setup as Setup
import Spec.Markup as Markup
import Spec.Markup.Selector exposing (..)
import Spec.Markup.Event as Event
import Spec.Claim exposing (..)
import Spec.Observer as Observer
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
        , Spec.File.select [ Spec.File.withText "my-fun-file.txt" "This is such a fun file!" ]
        ]
      |> it "finds the file" (
        Observer.observeModel .uploadedFileContents
          |> expect (isSomethingWhere <| isEqual Debug.toString "This is such a fun file!")
      )
    )
  ]


main =
  Runner.program
    [ fileSpec
    ]