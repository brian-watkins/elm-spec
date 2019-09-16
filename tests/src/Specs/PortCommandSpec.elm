port module Specs.PortCommandSpec exposing (..)

import Spec exposing (Spec)
import Spec.Subject as Subject
import Spec.Scenario exposing (..)
import Spec.Port as Port
import Spec.Observer as Observer
import Runner
import Json.Decode as Json
import Json.Encode as Encode


witnessPortCommandFromInitSpec : Spec Model Msg
witnessPortCommandFromInitSpec =
  Spec.describe "a worker with a port"
  [ scenario "commands sent via a port are observed" (
      Subject.init ( { count = 0 }, sendTestMessageOut "From init!")
        |> Subject.withUpdate testUpdate
        |> Port.observe "sendTestMessageOut"
    )
    |> it "sends the expected message" (
      Port.expect "sendTestMessageOut" Json.string <|
        Observer.isEqual [ "From init!" ]
    )
  ]


witnessMultiplePortCommandsFromInitSpec : Spec Model Msg
witnessMultiplePortCommandsFromInitSpec =
  Spec.describe "a worker with a port"
  [ scenario "multiple port commands are witnessed" (
      Subject.init
          ( {count = 0}
          , Cmd.batch [ sendTestMessageOut "One", sendTestMessageOut "Two", sendTestMessageOut "Three" ]
          )
        |> Subject.withUpdate testUpdate
        |> Port.observe "sendTestMessageOut"
    )
    |> it "records all the messages sent" (
      Port.expect "sendTestMessageOut" Json.string <|
        Observer.isEqual [ "One", "Two", "Three" ]
    )
  ]


testUpdate : Msg -> Model -> ( Model, Cmd Msg )
testUpdate _ model =
  ( model, Cmd.none )


selectSpec : String -> Maybe (Spec Model Msg)
selectSpec name =
  case name of
    "one" -> Just witnessPortCommandFromInitSpec
    "many" -> Just witnessMultiplePortCommandsFromInitSpec
    _ -> Nothing


type Msg
  = Msg


type alias Model =
  { count: Int
  }


port sendTestMessageOut : String -> Cmd msg


main =
  Runner.program selectSpec