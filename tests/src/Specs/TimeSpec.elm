module Specs.TimeSpec exposing (..)

import Spec exposing (Spec)
import Spec.Subject as Subject
import Spec.Port as Port
import Spec.Time
import Spec.Observer as Observer
import Spec.Context as Context
import Runner
import Task
import Json.Encode as Encode
import Time exposing (Posix)


countTimePassingSpec : Spec Model Msg
countTimePassingSpec =
  Spec.given "a worker that subscribes to the time" (
    Subject.init ( { count = 0 }, Cmd.none )
      |> Subject.withUpdate testUpdate
      |> Subject.withSubscriptions testSubscriptions
      |> Spec.Time.fake
  )
  |> Spec.when "time passes"
    [ Spec.Time.tick 1000
    , Spec.Time.tick 1000
    , Spec.Time.tick 1000
    , Spec.Time.tick 1000
    ]
  |> Spec.it "updates the model" (
    Context.expectModel <|
      \model ->
        Observer.isEqual 4 model.count
  )


testUpdate : Msg -> Model -> ( Model, Cmd Msg )
testUpdate msg model =
  case msg of
    ReceivedTime time ->
      ( { model | count = model.count + 1 }, Cmd.none )


selectSpec : String -> Spec Model Msg
selectSpec name =
  countTimePassingSpec


type Msg
  = ReceivedTime Posix


type alias Model =
  { count: Int
  }


testSubscriptions : Model -> Sub Msg
testSubscriptions model =
  Time.every 1000 ReceivedTime


main =
  Runner.program selectSpec