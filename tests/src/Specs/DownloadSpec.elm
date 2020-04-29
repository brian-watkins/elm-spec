module Specs.DownloadSpec exposing (main)

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
import File.Download as Download
import Runner
import Specs.Helpers exposing (..)


downloadFileSpec : Spec Model Msg
downloadFileSpec =
  describe "downloading a file"
  [ scenario "the file is downloaded" (
      given (
        Setup.initWithModel testModel
          |> Setup.withView testView
          |> Setup.withUpdate testUpdate
      )
      |> when "the file is downloaded"
        [ Markup.target << by [ id "start-download" ]
        , Event.click
        ]
      |> it "downloads the file" (
        Spec.File.observeDownloads
          |> expect (isListWhereItemAt 0 <| satisfying
            [ Spec.File.name <| equals "funFile.txt"
            , Spec.File.text <| equals "Here is some fun text!"
            ]
          )
      )
    )
  ]


claimFailureSpec : Spec Model Msg
claimFailureSpec =
  describe "downloaded file fails claims"
  [ scenario "the file is downloaded" (
      given (
        Setup.initWithModel testModel
          |> Setup.withView testView
          |> Setup.withUpdate testUpdate
      )
      |> when "the file is downloaded"
        [ Markup.target << by [ id "start-download" ]
        , Event.click
        ]
      |> observeThat
        [ it "gets the file name" (
            Spec.File.observeDownloads
              |> expect (isListWhereItemAt 0 <| Spec.File.name <| equals "funnyText.text")
          )
        , it "gets the file text" (
            Spec.File.observeDownloads
              |> expect (isListWhereItemAt 0 <| Spec.File.text <| equals "blah")
          )
        ]
    )
  ]


type Msg
  = StartDownload


type alias Model =
  { clicks: Int
  }


testModel =
  { clicks = 0
  }


testView : Model -> Html Msg
testView model =
  Html.div []
  [ Html.button [ Attr.id "start-download", Events.onClick StartDownload ] [ Html.text "Download File!" ]
  ]


testUpdate : Msg -> Model -> ( Model, Cmd Msg )
testUpdate msg model =
  case msg of
    StartDownload ->
      ( model, Download.string "funFile.txt" "text/plain" "Here is some fun text!" )


selectSpec : String -> Maybe (Spec Model Msg)
selectSpec name =
  case name of
    "downloadFile" -> Just downloadFileSpec
    "claimFailure" -> Just claimFailureSpec
    _ -> Nothing


main =
  Runner.browserProgram selectSpec

