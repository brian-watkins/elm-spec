module Specs.TimeSpec exposing (..)

import Spec exposing (Spec)
import Spec.Subject as Subject
import Spec.Port as Port
import Spec.Scenario exposing (..)
import Spec.Time
import Spec.Claim as Claim
import Spec.Observation as Observation
import Runner
import Task
import Json.Encode as Encode
import Time exposing (Posix)


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
        Observation.selectModel .count
          |> expect (Claim.isEqual 4)
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