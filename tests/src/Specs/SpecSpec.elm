port module Specs.SpecSpec exposing (..)

import Spec exposing (Spec)
import Spec.Subject as Subject
import Spec.Port as Port
import Observer
import Runner
import Json.Encode as Encode


multipleWhenSpec : Spec Model Msg
multipleWhenSpec =
  Spec.given (
    Subject.worker (\_ -> ({counts = []}, Cmd.none)) testUpdate
      |> Subject.withSubscriptions testSubscriptions
  )
  |> Spec.when "the first sub is sent"
    [ Port.send "specSpecSub" (Encode.object [ ("number", Encode.int 41) ])
    ]
  |> Spec.when "a second sub is sent"
    [ Port.send "specSpecSub" (Encode.object [ ("number", Encode.int 78) ])
    ]
  |> Spec.when "a third sub is sent"
    [ Port.send "specSpecSub" (Encode.object [ ("number", Encode.int 39) ])
    ]
  |> Spec.it "updates the model with all three subscriptions" ( Spec.expectModel <|
      \model ->
        Observer.isEqual [ 39, 78, 41 ] model.counts
  )


testUpdate : Msg -> Model -> ( Model, Cmd Msg )
testUpdate msg model =
  case msg of
    ReceivedSuperObject superObject ->
      ( { model | counts = superObject.number :: model.counts }, Cmd.none )


selectSpec : String -> Spec Model Msg
selectSpec name =
  multipleWhenSpec


type alias SuperObject =
  { number: Int
  }


type Msg
  = ReceivedSuperObject SuperObject


type alias Model =
  { counts: List Int
  }


port specSpecSub : (SuperObject -> msg) -> Sub msg


testSubscriptions : Model -> Sub Msg
testSubscriptions model =
  specSpecSub ReceivedSuperObject

main =
  Runner.program selectSpec