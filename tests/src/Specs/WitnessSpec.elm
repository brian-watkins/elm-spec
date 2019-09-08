port module Specs.WitnessSpec exposing (..)

import Spec exposing (Spec)
import Spec.Subject as Subject
import Spec.Message exposing (Message)
import Spec.Port as Port
import Spec.Witness as Witness exposing (Witness)
import Json.Encode as Encode
import Runner


spySpec : Spec Model Msg
spySpec =
  Spec.describe "a fragment injected with a cmd-generating function"
  [ Spec.scenario "the witness is called the expected number of times" testSubject
      |> triggerInjectedFunctionWith 88
      |> Spec.it "records the call to the injected function" (
        Witness.expect "injected" (Witness.hasStatements 1)
      )
  , Spec.scenario "the witness is never triggered" testSubject
      |> Spec.it "fails" (
        Witness.expect "injected" (Witness.hasStatements 1)
      )
  , Spec.scenario "the witness has too few statements" testSubject
      |> triggerInjectedFunctionWith 88
      |> Spec.it "fails" (
        Witness.expect "injected" (Witness.hasStatements 17)
      )
  ]


testSubject =
  Subject.initWithModel { count = 0 }
    |> Witness.forUpdate (\witness -> testUpdate <| \_ -> Witness.spy "injected" witness)
    |> Subject.withSubscriptions testSubscriptions
    |> Subject.withEffects [ { home = "test", name = "some-message", body = Encode.null } ]


triggerInjectedFunctionWith number =
  Spec.when "a message is sent that triggers the injected function"
  [ Port.send "witnessSpecSub" <| Encode.int 88
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
  Just spySpec


main =
  Runner.program selectSpec