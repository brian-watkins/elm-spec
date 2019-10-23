port module Specs.ProcessCommandSpec exposing (..)

import Spec exposing (Spec)
import Spec.Subject as Subject
import Spec.Scenario exposing (..)
import Spec.Port as Port
import Spec.Claim as Claim
import Spec.Observation as Observation
import Runner
import Json.Encode as Encode
import Json.Decode as Json
import Task


processCommandSpec : Spec Model Msg
processCommandSpec =
  Spec.describe "a worker"
  [ scenario "a command is sent by the update function and processed" (
      given (
        Subject.init ( { count = 0, num = 0 }, Cmd.none )
          |> Subject.withUpdate testUpdate
          |> Subject.withSubscriptions testSubscriptions
          |> Port.observe "sendSomethingOut"
      )
      |> when "a subscription message is sent"
        [ Port.send "listenForObject" (Encode.object [ ("number", Encode.int 41) ])
        ]
      |> it "sends the port command the specified number of times" (
        Port.expect "sendSomethingOut" Json.string <|
          \messages ->
            List.length messages
              |> Claim.isEqual 42
      )
    )
  ]


processBatchedTerminatingAndNoCallbackCommands : Spec Model Msg
processBatchedTerminatingAndNoCallbackCommands =
  Spec.describe "a worker"
  [ scenario "commands with no callback are sent from the update function" (
      given (
        Subject.init ( { count = 0, num = 0 }, Cmd.none )
          |> Subject.withUpdate testUpdate
          |> Subject.withSubscriptions testSubscriptions
          |> Port.observe "sendSomethingOut"
      )
      |> when "many subscription messages are sent" (
        List.range 0 5
          |> List.map (\num -> Port.send "listenForObject" (Encode.object [ ("number", Encode.int num) ]))
      )
      |> observeThat
        [ it "sends all the commands" (
            Port.expect "sendSomethingOut" Json.string <|
              \messages ->
                List.length messages
                  |> Claim.isEqual 21
          )
        , it "it ends up with the right tally" (
            Observation.selectModel .num
              |> expect (Claim.isEqual 35)
          )
        ]
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