port module Specs.SubscriptionSpec exposing (..)

import Spec exposing (Spec)
import Spec.Subject as Subject
import Spec.Port as Port
import Observer
import Runner
import Task
import Json.Encode as Encode


sendsSubscriptionSpec : Spec Model Msg
sendsSubscriptionSpec =
  Spec.given (
    Subject.worker (\_ -> ({count = 0}, Cmd.none)) testUpdate
      |> Subject.withSubscriptions testSubscriptions
  )
  |> Spec.when
    [ Port.send "listenForSuperObject" (Encode.object [ ("number", Encode.int 41) ])
    , Port.send "listenForSuperObject" (Encode.object [ ("number", Encode.int 78) ])
    ]
  |> Spec.it "updates the model" (
    Spec.expectModel <|
      \model ->
        Observer.isEqual 78 model.count
  )


testUpdate : Msg -> Model -> ( Model, Cmd Msg )
testUpdate msg model =
  case msg of
    ReceivedSuperObject superObject ->
      ( { model | count = superObject.number }, Cmd.none )


selectSpec : String -> Spec Model Msg
selectSpec name =
  sendsSubscriptionSpec


type alias SuperObject =
  { number: Int
  }


type Msg
  = ReceivedSuperObject SuperObject


type alias Model =
  { count: Int
  }


port listenForSuperObject : (SuperObject -> msg) -> Sub msg


testSubscriptions : Model -> Sub Msg
testSubscriptions model =
  listenForSuperObject ReceivedSuperObject

main =
  Runner.program selectSpec