module Specs.CommandSpec exposing (..)

import Spec exposing (..)
import Spec.Setup as Setup
import Spec.Observer as Observer
import Spec.Command as Command
import Runner
import Specs.Helpers exposing (..)


sendMessageToUpdateSpec : Spec Model Msg
sendMessageToUpdateSpec =
  Spec.describe "a worker"
  [ scenario "messages are sent to the update function" (
      given (
        Setup.init ( { numbers = [] }, Cmd.none )
          |> Setup.withUpdate testUpdate
      )
      |> when "messages are sent to the update function"
        [ Command.send <| Command.fake <| ReceivedNumber 8
        , Command.send <| Command.fake <| ReceivedNumber 4
        , Command.send Cmd.none
        , Command.send <| Command.fake <| ReceivedNumber 21
        ]
      |> it "behaves as expected" (
        Observer.observeModel .numbers
          |> expect (equals [ 21, 4, 8 ])
      )
    )
  , scenario "sending Cmd.none" (
      given (
        Setup.init ( { numbers = [] }, Cmd.none )
          |> Setup.withUpdate testUpdate
      )
      |> when "a message is sent along with Cmd.none"
        [ Command.send <| Command.fake <| ReceivedNumber 8
        , Command.send <| Cmd.none
        , Command.send <| Command.fake <| ReceivedNumber 21
        ]
      |> it "behaves as expected" (
        Observer.observeModel .numbers
          |> expect (equals [ 21, 8 ])
      )
    )
  ]


testUpdate : Msg -> Model -> ( Model, Cmd Msg )
testUpdate msg model =
  case msg of
    ReceivedNumber number ->
      ( { model | numbers = number :: model.numbers }, Cmd.none )


selectSpec : String -> Maybe (Spec Model Msg)
selectSpec _ =
  Just sendMessageToUpdateSpec


type Msg
  = ReceivedNumber Int


type alias Model =
  { numbers: List Int
  }


main =
  Runner.program selectSpec