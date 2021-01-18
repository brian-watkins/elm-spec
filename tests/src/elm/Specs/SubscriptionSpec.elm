port module Specs.SubscriptionSpec exposing (..)

import Spec exposing (..)
import Spec.Setup as Setup
import Spec.Port as Port
import Spec.Observer as Observer
import Spec.Claim exposing (..)
import Spec.Http
import Spec.Http.Route exposing (..)
import Spec.Http.Stub as Stub
import Runner
import Task
import Http
import Json.Encode as Encode
import Specs.Helpers exposing (..)


sendsSubscriptionSpec : Spec Model Msg
sendsSubscriptionSpec =
  Spec.describe "a worker with subscriptions"
  [ scenario "subscriptions are registered always" (
      given (
        Setup.init ( { count = 0, subscribe = True }, Cmd.none )
          |> Setup.withUpdate testUpdate
          |> Setup.withSubscriptions testSubscriptions
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
        Setup.init ( { count = 0, subscribe = False }, Cmd.none )
          |> Setup.withUpdate testUpdate
          |> Setup.withSubscriptions testVariableSubscriptions
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
        Setup.init ( { count = 0, subscribe = True }, Cmd.none )
          |> Setup.withUpdate testUpdate
          |> Setup.withSubscriptions testSubscriptions
      )
      |> when "some subscription messages are sent"
        [ Port.send "unknown-subscription" (Encode.object [ ("number", Encode.int 41) ])
        ]
      |> it "fails" (
        Observer.observeModel .count
          |> expect (equals 78)
      )
    )
  , scenario "send subscription message with bad shape" (
      given (
        Setup.initWithModel { count = 0, subscribe = True }
          |> Setup.withUpdate testUpdate
          |> Setup.withSubscriptions testSubscriptions
      )
      |> when "bad subscription message is sent"
        [ Port.send "listenForSuperObject" (Encode.object [ ("somethingWeird", Encode.string "blah") ])
        , Port.send "listenForSuperObject" (Encode.object [ ("number", Encode.int 78) ])
        ]
      |> itShouldHaveFailedAlready
    )
  ]


multipleSubscriberSpec : Spec Model Msg
multipleSubscriberSpec =
  describe "multiple subscribers for one subscription"
  [ scenario "receive a subscription message" (
      given (
        Setup.initWithModel { count = 0, subscribe = True }
          |> Setup.withUpdate testUpdate
          |> Setup.withSubscriptions testMultipleSubscriptions
          |> Stub.serve
            [ Stub.for (get "http://fake-stuff.com/fake")
            ]
      )
      |> when "a message is sent"
        [ Port.send "listenForSuperObject" (Encode.object [ ("number", Encode.int 91) ])
        ]
      |> observeThat
        [ it "updates the model" (
            Observer.observeModel .count
              |> expect (equals 91)
          )
        , it "makes a request" (
            Spec.Http.observeRequests (get "http://fake-stuff.com/fake")
              |> expect (isListWithLength 1)
          )
        ]
    )
  , scenario "one of the actions aborts the spec" (
      given (
        Setup.initWithModel { count = 0, subscribe = True }
          |> Setup.withUpdate testUpdate
          |> Setup.withSubscriptions testMultipleSubscriptions
          |> Stub.serve
            [ Stub.for (get "http://fake-stuff.com/fake")
                |> Stub.withBody (Stub.withTextAtPath "./blah/unknown/file.txt")
            ]
      )
      |> when "a message is sent"
        [ Port.send "listenForSuperObject" (Encode.object [ ("number", Encode.int 91) ])
        ]
      |> itShouldHaveFailedAlready
    )
  ]


testUpdate : Msg -> Model -> ( Model, Cmd Msg )
testUpdate msg model =
  case msg of
    ReceivedSuperObject superObject ->
      ( { model | count = superObject.number }, Cmd.none )
    AlsoReceivedSuperObject superObject ->
      ( model
      , Http.get
          { url = "http://fake-stuff.com/fake"
          , expect = Http.expectString GotResponse
          }
      )
    UpdateSubscription updated ->
      ( { model | subscribe = updated }, Cmd.none )
    GotResponse _ ->
      ( model, Cmd.none )


type alias SuperObject =
  { number: Int
  }


type Msg
  = ReceivedSuperObject SuperObject
  | AlsoReceivedSuperObject SuperObject
  | UpdateSubscription Bool
  | GotResponse (Result Http.Error String)


type alias Model =
  { count: Int
  , subscribe: Bool
  }


port listenForSuperObject : (SuperObject -> msg) -> Sub msg
port enableSubscription : (Bool -> msg) -> Sub msg

testSubscriptions : Model -> Sub Msg
testSubscriptions model =
  listenForSuperObject ReceivedSuperObject


testMultipleSubscriptions : Model -> Sub Msg
testMultipleSubscriptions model =
  Sub.batch
    [ listenForSuperObject ReceivedSuperObject
    , listenForSuperObject AlsoReceivedSuperObject
    ]


testVariableSubscriptions : Model -> Sub Msg
testVariableSubscriptions model =
  Sub.batch
  [ enableSubscription UpdateSubscription
  , if model.subscribe == True then
      listenForSuperObject ReceivedSuperObject
    else
      Sub.none
  ]


selectSpec : String -> Maybe (Spec Model Msg)
selectSpec name =
  case name of
    "send" -> Just sendsSubscriptionSpec
    "multipleSubscribers" -> Just multipleSubscriberSpec
    _ -> Nothing


main =
  Runner.program selectSpec