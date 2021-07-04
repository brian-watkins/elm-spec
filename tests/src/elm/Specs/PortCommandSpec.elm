port module Specs.PortCommandSpec exposing (..)

import Spec exposing (..)
import Spec.Setup as Setup
import Spec.Port as Port
import Spec.Claim as Claim
import Spec.Command
import Specs.Helpers exposing (..)
import Runner
import Json.Decode as Json


witnessPortCommandFromInitSpec : Spec Model Msg
witnessPortCommandFromInitSpec =
  Spec.describe "a worker with a port"
  [ scenario "commands sent via a port are observed" (
      given (
        Setup.init ( { count = 0 }, sendTestMessageOut "From init!")
          |> Setup.withUpdate testUpdate
      )
      |> it "sends the expected message" (
        Port.observe "sendTestMessageOut" Json.string
          |> expect (equals [ "From init!" ])
      )
    )
  , scenario "multiple port messages are observed in the right order" (
      given (
        Setup.initWithModel { count = 0 }
          |> Setup.withUpdate testUpdate
      )
      |> when "port messages are sent"
        [ Spec.Command.send <| sendTestMessageOut "From step 1"
        , Spec.Command.send <| sendTestMessageOut "From step 2"
        , Spec.Command.send <| sendTestMessageOut "From step 3"
        ]
      |> it "records the messages in the proper order" (
        Port.observe "sendTestMessageOut" Json.string
          |> expect (equals
            [ "From step 1"
            , "From step 2"
            , "From step 3"
            ]
          )
      )
    )
  , scenario "observing the same port in another scenario" (
      given (
        Setup.init ( { count = 0 }, sendTestMessageOut "From init in another scenario!")
          |> Setup.withUpdate testUpdate
      )
      |> it "resets the subscription between scenarios so only one request is observed" (
        Port.observe "sendTestMessageOut" Json.string
          |> expect (equals [ "From init in another scenario!" ])
      )
    )
  , scenario "observing a port that is not being recorded" (
      given (
        Setup.init ( { count = 0 }, sendTestMessageOut "Some message!")
          |> Setup.withUpdate testUpdate
      )
      |> it "fails" (
        Port.observe "some-other-port" Json.string
          |> expect (equals [ "Unknown!" ])
      )
    )
  , scenario "decoding a port value with the wrong decoder" (
      given (
        Setup.init ( { count = 0 }, sendTestMessageOut "From init!")
          |> Setup.withUpdate testUpdate
      )
      |> it "fails" (
        Port.observe "sendTestMessageOut" Json.int
          |> expect (equals [ 17 ])
      )
    )
  ]


witnessMultiplePortCommandsFromInitSpec : Spec Model Msg
witnessMultiplePortCommandsFromInitSpec =
  Spec.describe "a worker with a port"
  [ scenario "multiple port commands are witnessed" (
      given (
        Setup.init
          ( {count = 0}
          , Cmd.batch [ sendTestMessageOut "One", sendTestMessageOut "Two", sendTestMessageOut "Three" ]
          )
        |> Setup.withUpdate testUpdate
      )
      |> it "records all the messages sent" (
        Port.observe "sendTestMessageOut" Json.string
          |> expect (Claim.satisfying
            [ Claim.isTrue << List.member "One"
            , Claim.isTrue << List.member "Two"
            , Claim.isTrue << List.member "Three"
            ]
          )
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