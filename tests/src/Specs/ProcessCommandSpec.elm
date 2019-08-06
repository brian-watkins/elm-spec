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
    Subject.worker (\_ -> ({count = 0}, Cmd.none)) testUpdate
      |> Subject.withSubscriptions testSubscriptions
      |> Port.observe "sendSomethingOut"
  )
  |> Spec.when
    [ Port.send "listenForObject" (Encode.object [ ("number", Encode.int 41) ])
    ]
  |> Spec.it "sends the port command the specified number of times" (
    Port.expect "sendSomethingOut" Json.string <|
      \messages ->
        List.length messages
          |> Observer.isEqual 42
  )


testUpdate : Msg -> Model -> ( Model, Cmd Msg )
testUpdate msg model =
  case msg of
    ReceivedSuperObject superObject ->
      ( { model | count = superObject.number }
      , Cmd.batch
        [ sendSomethingOut <| "test-message-" ++ String.fromInt superObject.number
        , if superObject.number > 0 then
            Task.succeed { number = superObject.number - 1 }
              |> Task.perform ReceivedSuperObject
          else
            Cmd.none
        ]
      )


selectSpec : String -> Spec Model Msg
selectSpec name =
  processCommandSpec


type alias SuperObject =
  { number: Int
  }


type Msg
  = ReceivedSuperObject SuperObject


type alias Model =
  { count: Int
  }


port listenForObject : (SuperObject -> msg) -> Sub msg
port sendSomethingOut : String -> Cmd msg


testSubscriptions : Model -> Sub Msg
testSubscriptions model =
  listenForObject ReceivedSuperObject


main =
  Runner.program selectSpec