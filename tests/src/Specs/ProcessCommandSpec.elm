port module Specs.ProcessCommandSpec exposing (..)

import Spec exposing (Spec)
import Spec.Subject as Subject
import Spec.Port as Port
import Spec.Observer as Observer
import Spec.Actual as Actual
import Runner
import Json.Encode as Encode
import Json.Decode as Json
import Task


processCommandSpec : Spec Model Msg
processCommandSpec =
  Spec.describe "a worker"
  [ Spec.scenario "a command is sent by the update function and processed" (
      Subject.init ( { count = 0, num = 0 }, Cmd.none )
        |> Subject.withUpdate testUpdate
        |> Subject.withSubscriptions testSubscriptions
        |> Port.observe "sendSomethingOut"
    )
    |> Spec.when "a subscription message is sent"
      [ Port.send "listenForObject" (Encode.object [ ("number", Encode.int 41) ])
      ]
    |> Spec.it "sends the port command the specified number of times" (
      Port.expect "sendSomethingOut" Json.string <|
        \messages ->
          List.length messages
            |> Observer.isEqual 42
    )
  ]


processBatchedTerminatingAndNoCallbackCommands : Spec Model Msg
processBatchedTerminatingAndNoCallbackCommands =
  Spec.describe "a worker"
  [ Spec.scenario "commands with no callback are sent from the update function" (
      Subject.init ( { count = 0, num = 0 }, Cmd.none )
        |> Subject.withUpdate testUpdate
        |> Subject.withSubscriptions testSubscriptions
        |> Port.observe "sendSomethingOut"
    )
    |> Spec.when "many subscription messages are sent" (
      List.range 0 5
        |> List.map (\num -> Port.send "listenForObject" (Encode.object [ ("number", Encode.int num) ]))
    )
    |> Spec.it "sends all the commands" (
      Port.expect "sendSomethingOut" Json.string <|
        \messages ->
          List.length messages
            |> Observer.isEqual 21
    )
    |> Spec.it "it ends up with the right tally" (
      Actual.model
        |> Actual.map .num
        |> Spec.expect (Observer.isEqual 35)
    )
  ]


testUpdate : Msg -> Model -> ( Model, Cmd Msg )
testUpdate msg model =
  case msg of
    Tally num ->
      ( { model | num = model.num + num }, Cmd.none )
    ReceivedSuperObject superObject ->
      ( { model | count = superObject.number }
      , Cmd.batch
        [ sendNonTerminatingCommand superObject.number
        , if superObject.number > 0 then
            sendChainCommand superObject.number
          else
            Cmd.none
        , sendTerminatingCommand superObject.number
        ]
      )


sendChainCommand number =
  Task.succeed { number = number - 1 }
    |> Task.perform ReceivedSuperObject


sendNonTerminatingCommand number =
  "test-message-" ++ String.fromInt number
    |> sendSomethingOut


sendTerminatingCommand number =
  Task.succeed number
    |> Task.perform Tally


selectSpec : String -> Maybe (Spec Model Msg)
selectSpec name =
  case name of
    "terminatingAndNonTerminating" -> Just processBatchedTerminatingAndNoCallbackCommands
    "processCommand" -> Just processCommandSpec
    _ -> Nothing


type alias SuperObject =
  { number: Int
  }


type Msg
  = ReceivedSuperObject SuperObject
  | Tally Int


type alias Model =
  { count: Int
  , num: Int
  }


port listenForObject : (SuperObject -> msg) -> Sub msg
port sendSomethingOut : String -> Cmd msg


testSubscriptions : Model -> Sub Msg
testSubscriptions model =
  listenForObject ReceivedSuperObject


main =
  Runner.program selectSpec