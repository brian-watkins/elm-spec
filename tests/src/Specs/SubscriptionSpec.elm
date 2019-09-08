port module Specs.SubscriptionSpec exposing (..)

import Spec exposing (Spec)
import Spec.Subject as Subject
import Spec.Port as Port
import Spec.Observer as Observer
import Spec.Actual as Actual
import Runner
import Task
import Json.Encode as Encode


sendsSubscriptionSpec : Spec Model Msg
sendsSubscriptionSpec =
  Spec.describe "a worker with subscriptions"
  [ Spec.scenario "the worker receives subscriptions" (
      Subject.init ( { count = 0 }, Cmd.none )
        |> Subject.withUpdate testUpdate
        |> Subject.withSubscriptions testSubscriptions
    )
    |> Spec.when "some subscription messages are sent"
      [ Port.send "listenForSuperObject" (Encode.object [ ("number", Encode.int 41) ])
      , Port.send "listenForSuperObject" (Encode.object [ ("number", Encode.int 78) ])
      ]
    |> Spec.it "updates the model" (
      Actual.model
        |> Actual.map .count
        |> Spec.expect (Observer.isEqual 78)
    )
  ]


testUpdate : Msg -> Model -> ( Model, Cmd Msg )
testUpdate msg model =
  case msg of
    ReceivedSuperObject superObject ->
      ( { model | count = superObject.number }, Cmd.none )


selectSpec : String -> Maybe (Spec Model Msg)
selectSpec name =
  Just sendsSubscriptionSpec


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