port module Specs.ProcessCommandSpec exposing (..)

import Spec exposing (Spec)
import Spec.Subject as Subject
import Spec.Port as Port
import Observer
import Runner
import Json.Encode as Encode
import Json.Decode as Json


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
  |> Spec.it "sends the port command" (
    Port.expect "sendSomethingOut" Json.string (Observer.isEqual [ "test-message-41" ])
  )


testUpdate : Msg -> Model -> ( Model, Cmd Msg )
testUpdate msg model =
  case msg of
    ReceivedSuperObject superObject ->
      ( { model | count = superObject.number }
      , sendSomethingOut <| "test-message-" ++ String.fromInt superObject.number
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