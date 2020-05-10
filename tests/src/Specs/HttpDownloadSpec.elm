module Specs.HttpDownloadSpec exposing (main)

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
                |> Stub.withBody (Stub.fromBytes <| bytesFromString "Some text from bytes!")
            ]
      )
      |> when "an http request is made"
        [ Markup.target << by [ id "make-request" ]
        , Event.click
        ]
      |> it "displays the bytes" (
        Markup.observeElement
          |> Markup.query << by [ id "downloaded-bytes" ]
          |> expect (isSomethingWhere <| Markup.text <| equals "Got text: Some text from bytes!")
      )
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
                |> Stub.withBody (Stub.fromBytes <| bytesFromString "Some text from bytes!")
                |> Stub.withProgress (Stub.received 7)
            ]
      )
      |> when "an http request is made"
        [ Markup.target << by [ id "make-request" ]
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
        [ Markup.target << by [ id "make-request" ]
        , Event.click
        ]
      |> it "displays the progress" (
        Markup.observeElement
          |> Markup.query << by [ id "download-progress" ]
          |> expect (isSomethingWhere <| Markup.text <| equals "Downloaded 0%")
      )
    )
  ]


bytesFromString : String -> Bytes
bytesFromString =
  Bytes.encode << Bytes.string


type alias Model =
  { downloadedContent: Maybe Bytes
  , downloadProgress: Maybe Http.Progress
  }


testModel =
  { downloadedContent = Nothing
  , downloadProgress = Nothing
  }


type Msg
  = HandleClick
  | GotProgress Http.Progress
  | GotBytesResponse (Result String Bytes)


testView : Model -> Html Msg
testView model =
  Html.div []
  [ Html.button [ Attr.id "make-request", Events.onClick HandleClick ] [ Html.text "Make request!" ]
  , Html.div [ Attr.id "download-progress"]
    [ model.downloadProgress
        |> Maybe.map (\progress ->
          case progress of
            Http.Sending details ->
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
  ]


testUpdate : Msg -> Model -> (Model, Cmd Msg)
testUpdate msg model =
  case msg of
    HandleClick ->
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
    GotProgress progress ->
      ( { model | downloadProgress = Just progress }, Cmd.none )
    GotBytesResponse response ->
      case response of
        Ok bytes ->
          ( { model | downloadedContent = Just bytes }, Cmd.none )
        Err _ ->
          ( model, Cmd.none )


testSubscriptions : Model -> Sub Msg
testSubscriptions model =
  Http.track "download" GotProgress


handleBytesResponse : Http.Response Bytes -> Result String Bytes
handleBytesResponse response =
  case response of
    Http.GoodStatus_ metadata bytes ->
      Ok bytes
    _ ->
      Err "Something not good happened!"


selectSpec : String -> Maybe (Spec Model Msg)
selectSpec name =
  case name of
    "stubBytes" -> Just stubBytesSpec
    "bytesProgress" -> Just bytesProgressSpec
    _ -> Nothing


main =
  Runner.browserProgram selectSpec