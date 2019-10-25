port module Specs.PortCommandSpec exposing (..)

import Spec exposing (Spec)
import Spec.Subject as Subject
import Spec.Scenario exposing (..)
import Spec.Port as Port
import Spec.Claim as Claim
import Runner
import Json.Decode as Json
import Json.Encode as Encode


witnessPortCommandFromInitSpec : Spec Model Msg
witnessPortCommandFromInitSpec =
  Spec.describe "a worker with a port"
  [ scenario "commands sent via a port are observed" (
      given (
        Subject.init ( { count = 0 }, sendTestMessageOut "From init!")
          |> Subject.withUpdate testUpdate
          |> Port.record "sendTestMessageOut"
      )
      |> it "sends the expected message" (
        Port.observeRecordedValues "sendTestMessageOut" Json.string
          |> expect (Claim.isEqual [ "From init!" ])
      )
    )
  , scenario "observing a port that is not being recorded" (
      given (
        Subject.init ( { count = 0 }, sendTestMessageOut "Some message!")
          |> Subject.withUpdate testUpdate
          |> Port.record "sendTestMessageOut"
      )
      |> it "fails" (
        Port.observeRecordedValues "some-other-port" Json.string
          |> expect (Claim.isEqual [ "Unknown!" ])
      )
    )
  , scenario "decoding a port value with the wrong decoder" (
      given (
        Subject.init ( { count = 0 }, sendTestMessageOut "From init!")
          |> Subject.withUpdate testUpdate
          |> Port.record "sendTestMessageOut"
      )
      |> it "fails" (
        Port.observeRecordedValues "sendTestMessageOut" Json.int
          |> expect (Claim.isEqual [ 17 ])
      )
    )
  ]


witnessMultiplePortCommandsFromInitSpec : Spec Model Msg
witnessMultiplePortCommandsFromInitSpec =
  Spec.describe "a worker with a port"
  [ scenario "multiple port commands are witnessed" (
      given (
        Subject.init
          ( {count = 0}
          , Cmd.batch [ sendTestMessageOut "One", sendTestMessageOut "Two", sendTestMessageOut "Three" ]
          )
        |> Subject.withUpdate testUpdate
        |> Port.record "sendTestMessageOut"
      )
      |> it "records all the messages sent" (
        Port.observeRecordedValues "sendTestMessageOut" Json.string
          |> expect (Claim.isEqual [ "One", "Two", "Three" ])
      )
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