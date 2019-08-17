port module Specs.PortCommandSpec exposing (..)

import Spec exposing (Spec)
import Spec.Subject as Subject
import Spec.Port as Port
import Spec.Observer as Observer
import Runner
import Json.Decode as Json
import Json.Encode as Encode


witnessPortCommandFromInitSpec : Spec Model Msg
witnessPortCommandFromInitSpec =
  Spec.given "a worker with a port" (
    Subject.init ( { count = 0 }, sendTestMessageOut "From init!")
      |> Subject.withUpdate testUpdate
      |> Port.observe "sendTestMessageOut"
      |> Subject.pushEffect { home = "test", name = "something", body = Encode.null }
  )
  |> Spec.it "sends the expected message" (
    Port.expect "sendTestMessageOut" Json.string <|
      Observer.isEqual [ "From init!" ]
  )


witnessMultiplePortCommandsFromInitSpec : Spec Model Msg
witnessMultiplePortCommandsFromInitSpec =
  Spec.given "a worker with a port" (
    Subject.init
        ( {count = 0}
        , Cmd.batch [ sendTestMessageOut "One", sendTestMessageOut "Two", sendTestMessageOut "Three" ]
        )
      |> Subject.withUpdate testUpdate
      |> Port.observe "sendTestMessageOut"
  )
  |> Spec.it "records all the messages sent" (
    Port.expect "sendTestMessageOut" Json.string <|
      Observer.isEqual [ "One", "Two", "Three" ]
  )


testUpdate : Msg -> Model -> ( Model, Cmd Msg )
testUpdate _ model =
  ( model, Cmd.none )


selectSpec : String -> Spec Model Msg
selectSpec name =
  case name of
    "one" ->
      witnessPortCommandFromInitSpec
    "many" ->
      witnessMultiplePortCommandsFromInitSpec
    _ ->
      witnessPortCommandFromInitSpec


type Msg
  = Msg


type alias Model =
  { count: Int
  }


port sendTestMessageOut : String -> Cmd msg


main =
  Runner.program selectSpec