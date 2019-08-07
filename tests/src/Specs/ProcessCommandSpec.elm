port module Specs.ProcessCommandSpec exposing (..)

import Spec exposing (Spec)
import Spec.Subject as Subject
import Spec.Port as Port
import Observer
import Runner
import Json.Encode as Encode
import Json.Decode as Json
import Task


processCommandSpec : Spec Model Msg
processCommandSpec =
  Spec.given (
    Subject.worker (\_ -> ({count = 0, num = 0}, Cmd.none)) testUpdate
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


processBatchedTerminatingAndNoCallbackCommands : Spec Model Msg
processBatchedTerminatingAndNoCallbackCommands =
  Spec.given (
    Subject.worker (\_ -> ({count = 0, num = 0}, Cmd.none)) testUpdate
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
    Spec.expectModel <|
      \model ->
        Observer.isEqual 35 model.num
  )


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


selectSpec : String -> Spec Model Msg
selectSpec name =
  case name of
    "terminatingAndNonTerminating" ->
      processBatchedTerminatingAndNoCallbackCommands
    _ ->
      processCommandSpec


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