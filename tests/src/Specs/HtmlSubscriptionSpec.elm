port module Specs.HtmlSubscriptionSpec exposing (main)

import Spec exposing (..)
import Spec.Setup as Setup
import Spec.Markup as Markup
import Spec.Markup.Selector exposing (..)
import Spec.Port as Port
import Spec.Claim exposing (isSomethingWhere)
import Spec.Http
import Spec.Http.Stub as Stub
import Spec.Http.Route exposing (..)
import Spec.Time as Time
import Html exposing (Html)
import Html.Attributes as Attr
import Runner
import Specs.Helpers exposing (..)
import Json.Encode as Encode
import Http


sendSpec : Spec Model Msg
sendSpec =
  Spec.describe "send port subscription"
  [ scenario "sub message after configuring the environment" (
      given (
        Setup.initWithModel { words = "" }
          |> Setup.withUpdate testUpdate
          |> Setup.withView testView
          |> Setup.withSubscriptions testSubscriptions
          |> Stub.serve [ someRequestStub ]
      )
      |> when "a sub message is received"
        [ Port.send "sendSpecSub" <| Encode.int 27
        ]
      |> it "updates the view with the stubbed response" (
        Markup.observeElement
          |> Markup.query << by [ id "response-message" ]
          |> expect (isSomethingWhere <| Markup.text <| equals "The response is: You Win!")
      )
    )
  ]


someRequestStub =
  Stub.for (get "http://fun.com/fun?id=27")
    |> Stub.withBody (Stub.fromString "You Win")


type Msg
  = SubReceived Int
  | GotResponse (Result Http.Error String)


type alias Model =
  { words: String
  }


testUpdate : Msg -> Model -> ( Model, Cmd Msg )
testUpdate msg model =
  case msg of
    SubReceived count ->
      ( model
      , Http.get
        { url = "http://fun.com/fun?id=" ++ String.fromInt count
        , expect = Http.expectString GotResponse
        }
      )
    GotResponse result ->
      case result of
        Ok words ->
          ( { model | words = words }, Cmd.none )
        Err _ ->
          ( { model | words = "ERROR!" }, Cmd.none )


testView : Model -> Html Msg
testView model =
  Html.div []
  [ Html.div [ Attr.id "response-message" ]
    [ Html.text <| "The response is: " ++ model.words ++ "!" ]
  ]


port sendSpecSub : (Int -> msg) -> Sub msg


testSubscriptions : Model -> Sub Msg
testSubscriptions _ =
  sendSpecSub SubReceived


selectSpec : String -> Maybe (Spec Model Msg)
selectSpec name =
  case name of
    "send" -> Just sendSpec
    _ -> Nothing


main =
  Runner.browserProgram selectSpec