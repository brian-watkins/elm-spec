module WithFileSpecs.FileSpec exposing (main)

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
import Json.Encode as Encode


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
  , scenario "a binary file" (
      given (
        Setup.initWithModel App.defaultModel
          |> Setup.withUpdate App.update
          |> Setup.withView App.view
          |> Stub.serve
            [ Stub.for (get "http://fake-fun.com/api/files/21")
                |> Stub.withBody (Stub.withBytesAtPath "./specs/fixtures/awesome.txt")
            ]
      )
      |> when "a file is requested"
        [ Markup.target << by [ id "download-bytes" ]
        , Event.click
        ]
      |> it "downloads the file" (
        Observer.observeModel .downloadContents
          |> expect (isSomethingWhere <| isEqual Debug.toString "This is such an awesome file!")
      )
    )
  ]


downloadProgressSpec =
  describe "dowloading a file"
  [ scenario "a text file" (
      given (
        Setup.initWithModel App.defaultModel
          |> Setup.withUpdate App.update
          |> Setup.withView App.view
          |> Setup.withSubscriptions App.subscriptions
          |> Stub.serve
            [ Stub.for (get "http://fake-fun.com/api/files/21")
                |> Stub.withBody (Stub.withTextAtPath "./specs/fixtures/awesome.txt")
                |> Stub.withProgress (Stub.received 7)
            ]
      )
      |> when "a file is requested"
        [ Markup.target << by [ id "download-text" ]
        , Event.click
        ]
      |> it "shows the download percent" (
        Markup.observeElement
          |> Markup.query << by [ id "download-progress" ]
          |> expect (isSomethingWhere <| Markup.text <| isEqual Debug.toString "Downloaded 24%")
      )
    )
  , scenario "a binary file" (
      given (
        Setup.initWithModel App.defaultModel
          |> Setup.withUpdate App.update
          |> Setup.withView App.view
          |> Setup.withSubscriptions App.subscriptions
          |> Stub.serve
            [ Stub.for (get "http://fake-fun.com/api/files/21")
                |> Stub.withBody (Stub.withBytesAtPath "./specs/fixtures/awesome.txt")
                |> Stub.withProgress (Stub.received 12)
            ]
      )
      |> when "a file is requested"
        [ Markup.target << by [ id "download-bytes" ]
        , Event.click
        ]
      |> it "shows the download percent" (
        Markup.observeElement
          |> Markup.query << by [ id "download-progress" ]
          |> expect (isSomethingWhere <| Markup.text <| isEqual Debug.toString "Downloaded 41%")
      )
    )
  ]


contractSpec =
  describe "validating http requests"
  [ scenario "a valid request" (
      given (
        Setup.initWithModel App.defaultModel
          |> Setup.withUpdate App.update
          |> Setup.withView App.view
          |> Stub.validate "./specs/fixtures/reference/simple-api.yaml"
          |> Stub.serve
            [ Stub.for (get "http://fake-fun.com/api/messages")
                |> Stub.withBody (Stub.withJson <| Encode.list (\(id, text) ->
                    Encode.object [ ("id", Encode.string id), ("text", Encode.string text) ]
                  ) [ ("1", "hello"), ("2", "cool!") ]
                )
            ]
      )
      |> when "a file is requested"
        [ Markup.target << by [ id "get-messages" ]
        , Event.click
        ]
      |> it "gets the messages" (
        Observer.observeModel .messages
          |> expect (isListWithLength 2)
      )
    )
  ]

main =
  Runner.program
    [ fileSpec
    , downloadSpec
    , downloadProgressSpec
    , contractSpec
    ]