port module Specs.SubscriptionSpec exposing (..)

import Spec exposing (Spec)
import Spec.Program as Program
import Observer
import Runner
import Task
import Json.Encode as Encode


sendsSubscriptionSpec : Spec Model Msg
sendsSubscriptionSpec =
  Spec.given
    << Program.worker testUpdate
    << Program.withSubscriptions testSubscriptions
    << Program.withInit (\_ -> ({count = 0}, Cmd.none))
  |> Spec.when
    << Spec.send "listenForSuperObject" (Encode.object [ ("number", Encode.int 41) ])
    << Spec.send "listenForSuperObject" (Encode.object [ ("number", Encode.int 78) ])
  |> Spec.expectModel (\model ->
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