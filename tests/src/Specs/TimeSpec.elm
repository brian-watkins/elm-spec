module Specs.TimeSpec exposing (..)

import Spec exposing (Spec)
import Spec.Subject as Subject
import Spec.Port as Port
import Spec.Scenario exposing (..)
import Spec.Time
import Spec.Observer as Observer
import Runner
import Task
import Json.Encode as Encode
import Time exposing (Posix)
import Specs.Helpers exposing (..)


countTimePassingSpec : Spec Model Msg
countTimePassingSpec =
  Spec.describe "a worker that subscribes to the time"
  [ scenario "the time passes as expected" (
      given (
        Subject.init ( { count = 0 }, Cmd.none )
          |> Subject.withUpdate testUpdate
          |> Subject.withSubscriptions testSubscriptions
          |> Spec.Time.fake
      )
      |> when "time passes"
        [ Spec.Time.tick 1000
        , Spec.Time.tick 1000
        , Spec.Time.tick 1000
        , Spec.Time.tick 1000
        ]
      |> it "updates the model" (
        Observer.observeModel .count
          |> expect (equals 4)
      )
    )
  , scenario "another scenario runs" (
      given (
        Subject.init ( { count = 0 }, Cmd.none )
          |> Subject.withUpdate testUpdate
          |> Subject.withSubscriptions testSubscriptions
          |> Spec.Time.fake
      )
      |> when "time passes"
        [ Spec.Time.tick 1000
        , Spec.Time.tick 1000
        ]
      |> it "updates the model -- and doesn't carry over any intervals from the previous scenario" (
        Observer.observeModel .count
          |> expect (equals 2)
      )
    )
  ]


testUpdate : Msg -> Model -> ( Model, Cmd Msg )
testUpdate msg model =
  case msg of
    ReceivedTime time ->
      ( { model | count = model.count + 1 }, Cmd.none )


selectSpec : String -> Maybe (Spec Model Msg)
selectSpec name =
  Just countTimePassingSpec


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