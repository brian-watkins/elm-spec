port module Specs.SubscriptionSpec exposing (..)

import Spec exposing (..)
import Spec.Subject as Subject
import Spec.Port as Port
import Spec.Observer as Observer
import Runner
import Task
import Json.Encode as Encode
import Specs.Helpers exposing (..)


sendsSubscriptionSpec : Spec Model Msg
sendsSubscriptionSpec =
  Spec.describe "a worker with subscriptions"
  [ scenario "subscriptions are registered always" (
      given (
        Subject.init ( { count = 0, subscribe = True }, Cmd.none )
          |> Subject.withUpdate testUpdate
          |> Subject.withSubscriptions testSubscriptions
      )
      |> when "some subscription messages are sent"
        [ Port.send "listenForSuperObject" (Encode.object [ ("number", Encode.int 41) ])
        , Port.send "listenForSuperObject" (Encode.object [ ("number", Encode.int 78) ])
        ]
      |> it "updates the model" (
        Observer.observeModel .count
          |> expect (equals 78)
      )
    )
  , scenario "subscriptions are registered later depending on the model" (
      given (
        Subject.init ( { count = 0, subscribe = False }, Cmd.none )
          |> Subject.withUpdate testUpdate
          |> Subject.withSubscriptions testVariableSubscriptions
      )
      |> when "the subscription is enabled"
        [ Port.send "enableSubscription" (Encode.bool True)
        ]
      |> when "some subscription messages are sent"
        [ Port.send "listenForSuperObject" (Encode.object [ ("number", Encode.int 41) ])
        , Port.send "listenForSuperObject" (Encode.object [ ("number", Encode.int 78) ])
        ]
      |> it "updates the model" (
        Observer.observeModel .count
          |> expect (equals 78)
      )
    )
  , scenario "attempt to send unknown subscription" (
      given (
        Subject.init ( { count = 0, subscribe = True }, Cmd.none )
          |> Subject.withUpdate testUpdate
          |> Subject.withSubscriptions testSubscriptions
      )
      |> when "some subscription messages are sent"
        [ Port.send "unknown-subscription" (Encode.object [ ("number", Encode.int 41) ])
        ]
      |> it "fails" (
        Observer.observeModel .count
          |> expect (equals 78)
      )
    )
  ]


testUpdate : Msg -> Model -> ( Model, Cmd Msg )
testUpdate msg model =
  case msg of
    ReceivedSuperObject superObject ->
      ( { model | count = superObject.number }, Cmd.none )
    UpdateSubscription updated ->
      ( { model | subscribe = updated }, Cmd.none )


selectSpec : String -> Maybe (Spec Model Msg)
selectSpec name =
  Just sendsSubscriptionSpec


type alias SuperObject =
  { number: Int
  }


type Msg
  = ReceivedSuperObject SuperObject
  | UpdateSubscription Bool


type alias Model =
  { count: Int
  , subscribe: Bool
  }


port listenForSuperObject : (SuperObject -> msg) -> Sub msg
port enableSubscription : (Bool -> msg) -> Sub msg

testSubscriptions : Model -> Sub Msg
testSubscriptions model =
  listenForSuperObject ReceivedSuperObject

testVariableSubscriptions : Model -> Sub Msg
testVariableSubscriptions model =
  Sub.batch
  [ enableSubscription UpdateSubscription
  , if model.subscribe == True then
      listenForSuperObject ReceivedSuperObject
    else
      Sub.none
  ]

main =
  Runner.program selectSpec