module Specs.CommandSpec exposing (..)

import Spec exposing (Spec)
import Spec.Subject as Subject
import Spec.Observer as Observer
import Spec.Actual as Actual
import Spec.Command as Command
import Runner
import Task


sendMessageToUpdateSpec : Spec Model Msg
sendMessageToUpdateSpec =
  Spec.describe "a worker"
  [ Spec.scenario "messages are sent to the update function" (
      Subject.init ( { numbers = [] }, Cmd.none )
        |> Subject.withUpdate testUpdate
    )
    |> Spec.when "messages are sent to the update function"
      [ Command.send <| Command.fake <| ReceivedNumber 8
      , Command.send <| Command.fake <| ReceivedNumber 4
      , Command.send <| Command.fake <| ReceivedNumber 21
      ]
    |> Spec.it "behaves as expected" (
      Actual.model
        |> Actual.map .numbers
        |> Spec.expect (Observer.isEqual [ 21, 4, 8 ])
    )
  , Spec.scenario "sending Cmd.none" (
      Subject.init ( { numbers = [] }, Cmd.none )
        |> Subject.withUpdate testUpdate
    )
    |> Spec.when "a message is sent along with Cmd.none"
      [ Command.send <| Command.fake <| ReceivedNumber 8
      , Command.send <| Cmd.none
      , Command.send <| Command.fake <| ReceivedNumber 21
      ]
    |> Spec.it "behaves as expected" (
      Actual.model
        |> Actual.map .numbers
        |> Spec.expect (Observer.isEqual [ 21, 8 ])
    )
  ]


testUpdate : Msg -> Model -> ( Model, Cmd Msg )
testUpdate msg model =
  case msg of
    ReceivedNumber number ->
      ( { model | numbers = number :: model.numbers }, Cmd.none )


selectSpec : String -> Maybe (Spec Model Msg)
selectSpec name =
  Just sendMessageToUpdateSpec


type Msg
  = ReceivedNumber Int


type alias Model =
  { numbers: List Int
  }


main =
  Runner.program selectSpec