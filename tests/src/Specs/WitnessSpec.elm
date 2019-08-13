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
  Spec.given "a fragment injected with a cmd-generating function" (
    Subject.initWithModel { count = 0 }
      |> Witness.forUpdate (\witness -> testUpdate <| \_ -> Witness.spy "injected" witness)
      |> Subject.withSubscriptions testSubscriptions
  )
  |> Spec.when "a message is sent that triggers the injected function"
    [ Port.send "witnessSpecSub" <| Encode.int 88
    ]
  |> Spec.it "records the call to the injected function" (
    Witness.expect "injected" (Witness.hasReports 1)
  )
  |> Spec.suppose (
    Spec.given "the witness has no reports"
      >> Spec.it "fails" (
        Witness.expect "some-other-witness" (Witness.hasReports 1)
      )
  )
  |> Spec.suppose (
    Spec.given "the witness has too few reports"
      >> Spec.it "fails" (
        Witness.expect "injected" (Witness.hasReports 17)
      )
  )


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


selectSpec : String -> Spec Model Msg
selectSpec name =
  spySpec


main =
  Runner.program selectSpec