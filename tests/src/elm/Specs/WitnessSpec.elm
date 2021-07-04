port module Specs.WitnessSpec exposing (..)

import Spec exposing (..)
import Spec.Setup as Setup
import Spec.Claim as Claim
import Spec.Port as Port
import Spec.Witness as Witness
import Json.Encode as Encode
import Json.Decode as Json
import Runner
import Specs.Helpers exposing (..)


recordSpec : Spec Model Msg
recordSpec =
  Spec.describe "witness"
  [ scenario "the witness is called the expected number of times" (
      given testSubject
      |> triggerInjectedFunctionWith 88
      |> triggerInjectedFunctionWith 91
      |> triggerInjectedFunctionWith 14
      |> it "records statements about the injected function" (
        Witness.observe "injected" Json.int
          |> expect (
            Claim.isListWhere
              [ equals 88
              , equals 91
              , equals 14
              ]  
          )
      )
    )
  , scenario "the witness expectation fails" (
      given testSubject
      |> triggerInjectedFunctionWith 72
      |> it "fails" (
        Witness.observe "injected" Json.int
          |> expect (Claim.isListWithLength 3)
      )
    )
  , scenario "the witness statement decoder fails" (
      given testSubject
      |> triggerInjectedFunctionWith 72
      |> it "fails" (
        Witness.observe "injected" Json.string
          |> expect (Claim.isListWithLength 1)
      )
    )
  ]


record =
  Runner.elmSpecOut
    |> Witness.connect
    |> Witness.record


testSubject =
  Setup.initWithModel { count = 0 }
    |> Setup.withUpdate (
        testUpdate <| \num -> 
          record "injected" (Encode.int num)
      )
    |> Setup.withSubscriptions testSubscriptions


triggerInjectedFunctionWith number =
  when "a message is sent that triggers the injected function"
  [ Port.send "witnessSpecSub" <| Encode.int number
  ]


type Msg =
  ReceivedNumber Int


type alias Model =
  { count: Int
  }


testUpdate : (Int -> Cmd Msg) -> Msg -> Model -> (Model, Cmd Msg)
testUpdate injected msg model =
  case msg of
    ReceivedNumber num ->
      ( model, injected num )


port witnessSpecSub : (Int -> msg) -> Sub msg


testSubscriptions : Model -> Sub Msg
testSubscriptions _ =
  witnessSpecSub ReceivedNumber


selectSpec : String -> Maybe (Spec Model Msg)
selectSpec _ =
  Just recordSpec


main =
  Runner.program selectSpec