module Specs.HttpDownloadSpec exposing (main)

import Spec exposing (..)
import Spec.Setup as Setup
import Spec.Markup as Markup
import Spec.Claim exposing (..)
import Spec.Markup.Selector exposing (..)
import Spec.Markup.Event as Event
import Spec.Http.Stub as Stub
import Spec.Http.Route exposing (..)
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Http
import Bytes exposing (Bytes)
import Bytes.Encode as Bytes
import Bytes.Decode as Decode
import Runner
import Specs.Helpers exposing (..)


stubBytesSpec : Spec Model Msg
stubBytesSpec =
  describe "download bytes"
  [ scenario "stub request with bytes" (
      given (
        Setup.initWithModel testModel
          |> Setup.withView testView
          |> Setup.withUpdate testUpdate
          |> Stub.serve
            [ Stub.for (get "http://fake.api.com/files/12")
                |> Stub.withBody (Stub.withBytes <| bytesFromString "Some text from bytes!")
            ]
      )
      |> when "an http request is made"
        [ Markup.target << by [ id "make-bytes-request" ]
        , Event.click
        ]
      |> it "displays the bytes" (
        Markup.observeElement
          |> Markup.query << by [ id "downloaded-bytes" ]
          |> expect (isSomethingWhere <| Markup.text <| equals "Got text: Some text from bytes!")
      )
    )
  , scenario "stub request with bytes from file" (
      given (
        Setup.initWithModel testModel
          |> Setup.withView testView
          |> Setup.withUpdate testUpdate
          |> Stub.serve
            [ Stub.for (get "http://fake.api.com/files/12")
                |> Stub.withBody (Stub.withBytesAtPath "./fixtures/funFile.txt")
            ]
      )
      |> when "an http request is made"
        [ Markup.target << by [ id "make-bytes-request" ]
        , Event.click
        ]
      |> it "displays the bytes" (
        Markup.observeElement
          |> Markup.query << by [ id "downloaded-bytes" ]
          |> expect (isSomethingWhere <| Markup.text <| equals "Got text: Here is text from a fun file!")
      )
    )
  , scenario "bytes file not found" (
      given (
        Setup.initWithModel testModel
          |> Setup.withView testView
          |> Setup.withUpdate testUpdate
          |> Stub.serve
            [ Stub.for (get "http://fake.api.com/files/12")
                |> Stub.withBody (Stub.withBytesAtPath "./some/bad/path.txt")
            ]
      )
      |> when "an http request is made"
        [ Markup.target << by [ id "make-bytes-request" ]
        , Event.click
        ]
      |> itShouldHaveFailedAlready
    )
  ]


bytesProgressSpec : Spec Model Msg
bytesProgressSpec =
  describe "progress downloading bytes"
  [ scenario "with a stubbed response body" (
      given (
        Setup.initWithModel testModel
          |> Setup.withView testView
          |> Setup.withUpdate testUpdate
          |> Setup.withSubscriptions testSubscriptions
          |> Stub.serve
            [ Stub.for (get "http://fake.api.com/files/12")
                |> Stub.withBody (Stub.withBytes <| bytesFromString "Some text from bytes!")
                |> Stub.withProgress (Stub.received 7)
            ]
      )
      |> when "an http request is made"
        [ Markup.target << by [ id "make-bytes-request" ]
        , Event.click
        ]
      |> it "displays the progress" (
        Markup.observeElement
          |> Markup.query << by [ id "download-progress" ]
          |> expect (isSomethingWhere <| Markup.text <| equals "Downloaded 33%")
      )
    )
  , scenario "with an empty stubbed response body" (
      given (
        Setup.initWithModel testModel
          |> Setup.withView testView
          |> Setup.withUpdate testUpdate
          |> Setup.withSubscriptions testSubscriptions
          |> Stub.serve
            [ Stub.for (get "http://fake.api.com/files/12")
                |> Stub.withProgress (Stub.received 4000)
            ]
      )
      |> when "an http request is made"
        [ Markup.target << by [ id "make-bytes-request" ]
        , Event.click
        ]
      |> it "displays the progress" (
        Markup.observeElement
          |> Markup.query << by [ id "download-progress" ]
          |> expect (isSomethingWhere <| Markup.text <| equals "Downloaded 0%")
      )
    )
  , scenario "with a stubbed response body of bytes from a file" (
      given (
        Setup.initWithModel testModel
          |> Setup.withView testView
          |> Setup.withUpdate testUpdate
          |> Setup.withSubscriptions testSubscriptions
          |> Stub.serve
            [ Stub.for (get "http://fake.api.com/files/12")
                |> Stub.withBody (Stub.withBytesAtPath "./fixtures/funFile.txt")
                |> Stub.withProgress (Stub.received 18)
            ]
      )
      |> when "an http request is made"
        [ Markup.target << by [ id "make-bytes-request" ]
        , Event.click
        ]
      |> it "displays the progress" (
        Markup.observeElement
          |> Markup.query << by [ id "download-progress" ]
          |> expect (isSomethingWhere <| Markup.text <| equals "Downloaded 62%")
      )
    )
  , scenario "with a stubbed response body of text from a file" (
      given (
        Setup.initWithModel testModel
          |> Setup.withView testView
          |> Setup.withUpdate testUpdate
          |> Setup.withSubscriptions testSubscriptions
          |> Stub.serve
            [ Stub.for (get "http://fake.api.com/files/12")
                |> Stub.withBody (Stub.withTextAtPath "./fixtures/awesomeFile.txt")
                |> Stub.withProgress (Stub.received 2000)
            ]
      )
      |> when "an http request is made"
        [ Markup.target << by [ id "make-bytes-request" ]
        , Event.click
        ]
      |> it "displays the progress" (
        Markup.observeElement
          |> Markup.query << by [ id "download-progress" ]
          |> expect (isSomethingWhere <| Markup.text <| equals "Downloaded 8%")
      )
    )
  , scenario "with a stubbed response body of bytes from a file that cannot be read" (
      given (
        Setup.initWithModel testModel
          |> Setup.withView testView
          |> Setup.withUpdate testUpdate
          |> Setup.withSubscriptions testSubscriptions
          |> Stub.serve
            [ Stub.for (get "http://fake.api.com/files/12")
                |> Stub.withBody (Stub.withBytesAtPath "./some/wrong/path.txt")
                |> Stub.withProgress (Stub.received 18)
            ]
      )
      |> when "an http request is made"
        [ Markup.target << by [ id "make-bytes-request" ]
        , Event.click
        ]
      |> itShouldHaveFailedAlready
    )
  , scenario "with a stubbed response body of text from a file that cannot be read" (
      given (
        Setup.initWithModel testModel
          |> Setup.withView testView
          |> Setup.withUpdate testUpdate
          |> Setup.withSubscriptions testSubscriptions
          |> Stub.serve
            [ Stub.for (get "http://fake.api.com/files/12")
                |> Stub.withBody (Stub.withTextAtPath "./huh/what/file.txt")
                |> Stub.withProgress (Stub.received 2000)
            ]
      )
      |> when "an http request is made"
        [ Markup.target << by [ id "make-bytes-request" ]
        , Event.click
        ]
      |> itShouldHaveFailedAlready
    )
  ]


stubTextSpec : Spec Model Msg
stubTextSpec =
  describe "stub response with text"
  [ scenario "the text comes from a file" (
      given (
        Setup.initWithModel testModel
          |> Setup.withView testView
          |> Setup.withUpdate testUpdate
          |> Stub.serve
            [ Stub.for (get "http://fake.api.com/files/12")
                |> Stub.withBody (Stub.withTextAtPath "./fixtures/awesomeFile.txt")
            ]
      )
      |> when "an http request is made"
        [ Markup.target << by [ id "make-text-request" ]
        , Event.click
        ]
      |> it "displays the text" (
        Markup.observeElement
          |> Markup.query << by [ id "downloaded-text" ]
          |> expect (isSomethingWhere <| Markup.text <| isStringContaining 1 "And that was some awesome stuff!")
      )
    )
  , scenario "the file cannot be read" (
      given (
        Setup.initWithModel testModel
          |> Setup.withView testView
          |> Setup.withUpdate testUpdate
          |> Stub.serve
            [ Stub.for (get "http://fake.api.com/files/12")
                |> Stub.withBody (Stub.withTextAtPath "./some/nonExisting/file.txt")
            ]
      )
      |> when "an http request is made"
        [ Markup.target << by [ id "make-text-request" ]
        , Event.click
        ]
      |> itShouldHaveFailedAlready
    )
  ]


bytesFromString : String -> Bytes
bytesFromString =
  Bytes.encode << Bytes.string


type alias Model =
  { downloadedContent: Maybe Bytes
  , downloadedText: Maybe String
  , downloadProgress: Maybe Http.Progress
  }


testModel =
  { downloadedContent = Nothing
  , downloadedText = Nothing
  , downloadProgress = Nothing
  }


type Msg
  = MakeBytesRequest
  | MakeTextRequest
  | GotProgress Http.Progress
  | GotBytesResponse (Result String Bytes)
  | GotTextResponse (Result Http.Error String)


testView : Model -> Html Msg
testView model =
  Html.div []
  [ Html.button [ Attr.id "make-bytes-request", Events.onClick MakeBytesRequest ] [ Html.text "Make bytes request!" ]
  , Html.button [ Attr.id "make-text-request", Events.onClick MakeTextRequest ] [ Html.text "Make text request!" ]
  , Html.div [ Attr.id "download-progress"]
    [ model.downloadProgress
        |> Maybe.map (\progress ->
          case progress of
            Http.Sending _ ->
              Html.text "Sending ..."
            Http.Receiving details ->
              Html.text <| "Downloaded " ++ (String.fromInt <| round <| Http.fractionReceived details * 100) ++ "%"
        )
        |> Maybe.withDefault (Html.text "")
    ]
  , Html.div [ Attr.id "downloaded-bytes" ]
    [ model.downloadedContent
        |> Maybe.andThen (\bytes -> Decode.decode (Decode.string (Bytes.width bytes)) bytes)
        |> Maybe.map (\text -> Html.text <| "Got text: " ++ text)
        |> Maybe.withDefault (Html.text "Nothing downloaded yet!")
    ]
  , Html.div [ Attr.id "downloaded-text" ]
    [ model.downloadedText
        |> Maybe.map (\text -> Html.text <| "Got text: " ++ text)
        |> Maybe.withDefault (Html.text "Nothing downloaded yet!")
    ]
  ]


testUpdate : Msg -> Model -> (Model, Cmd Msg)
testUpdate msg model =
  case msg of
    MakeBytesRequest ->
      ( model
      , Http.request
        { method = "GET"
        , headers = []
        , url = "http://fake.api.com/files/12"
        , body = Http.emptyBody
        , expect = Http.expectBytesResponse GotBytesResponse handleBytesResponse 
        , timeout = Nothing
        , tracker = Just "download"
        }
      )
    MakeTextRequest ->
      ( model
      , Http.get
        { url = "http://fake.api.com/files/12"
        , expect = Http.expectString GotTextResponse
        }
      )
    GotProgress progress ->
      ( { model | downloadProgress = Just progress }, Cmd.none )
    GotBytesResponse response ->
      case response of
        Ok bytes ->
          ( { model | downloadedContent = Just bytes }, Cmd.none )
        Err _ ->
          ( model, Cmd.none )
    GotTextResponse response ->
      case response of
        Ok text ->
          ( { model | downloadedText = Just text }, Cmd.none )
        Err _ ->
          ( model, Cmd.none )


testSubscriptions : Model -> Sub Msg
testSubscriptions _ =
  Http.track "download" GotProgress


handleBytesResponse : Http.Response Bytes -> Result String Bytes
handleBytesResponse response =
  case response of
    Http.GoodStatus_ _ bytes ->
      Ok bytes
    _ ->
      Err "Something not good happened!"


selectSpec : String -> Maybe (Spec Model Msg)
selectSpec name =
  case name of
    "stubBytes" -> Just stubBytesSpec
    "stubText" -> Just stubTextSpec
    "bytesProgress" -> Just bytesProgressSpec
    _ -> Nothing


main =
  Runner.browserProgram selectSpec