port module Specs.WitnessSpec exposing (..)

import Spec exposing (Spec)
import Spec.Subject as Subject
import Spec.Scenario exposing (..)
import Spec.Message exposing (Message)
import Spec.Observer as Observer
import Spec.Port as Port
import Spec.Witness as Witness exposing (Witness)
import Json.Encode as Encode
import Json.Decode as Json
import Runner


recordSpec : Spec Model Msg
recordSpec =
  Spec.describe "witness"
  [ scenario "the witness is called the expected number of times" testSubject
      |> triggerInjectedFunctionWith 88
      |> triggerInjectedFunctionWith 91
      |> triggerInjectedFunctionWith 14
      |> it "records statements about the injected function" (
        Witness.expect "injected" Json.int (
          Observer.isList
            [ Observer.isEqual 88
            , Observer.isEqual 91
            , Observer.isEqual 14 
            ]
        )
      )
  , scenario "the witness expectation fails" testSubject
      |> triggerInjectedFunctionWith 72
      |> it "fails" (
        Witness.expect "injected" Json.int (Observer.isListWithLength 3)
      )
  ]


testSubject =
  Subject.initWithModel { count = 0 }
    |> Witness.forUpdate (\witness ->
        testUpdate <| \num -> 
          Witness.log "injected" (Encode.int num) witness
      )
    |> Subject.withSubscriptions testSubscriptions


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
selectSpec name =
  Just recordSpec


main =
  Runner.program selectSpec