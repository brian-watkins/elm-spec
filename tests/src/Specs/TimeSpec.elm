module Specs.TimeSpec exposing (..)

import Spec exposing (..)
import Spec.Subject as Subject
import Spec.Port as Port
import Spec.Time
import Spec.Observer as Observer
import Runner
import Task
import Json.Encode as Encode
import Time exposing (Posix, Zone)
import Specs.Helpers exposing (..)


stubTimeSpec : Spec Model Msg
stubTimeSpec =
  Spec.describe "stubbing the time"
  [ scenario "the curent time is requested in init" (
      given (
        Subject.init ( testModel, Time.now |> Task.perform ReceivedTime )
          |> Subject.withUpdate testUpdate
          |> Spec.Time.withTime 1111111111111
      )
      |> it "gets the stubbed time" (
        Observer.observeModel .current
          |> expect (equals <| Time.millisToPosix 1111111111111)
      )
    )
  , scenario "passing time" (
      given (
        Subject.init ( testModel, Time.now |> Task.perform ReceivedTime )
          |> Subject.withUpdate testUpdate
          |> Subject.withSubscriptions testSubscriptions
          |> Spec.Time.withTime 1111111111111
      )
      |> when "time passes"
        [ Spec.Time.tick 1000
        , Spec.Time.tick 1000
        ]
      |> it "increments the time beginning with the stubbed time" (
        Observer.observeModel .current
          |> expect (equals <| Time.millisToPosix 1111111113120)
      )
    )
  ]


stubZoneSpec : Spec Model Msg
stubZoneSpec =
  Spec.describe "stubbing the timezone"
  [ scenario "zone is requested in init" (
      given (
        Subject.init ( testModel, Time.here |> Task.perform ReceivedZone )
          |> Subject.withUpdate testUpdate
          |> Spec.Time.withTimezoneOffset (9 * 60)
      )
      |> it "gets the stubbed time" (
        Observer.observeModel .currentZone
          |> expect (equals <| Time.customZone (9 * 60) [])
      )
    )
  ]


countTimePassingSpec : Spec Model Msg
countTimePassingSpec =
  Spec.describe "a worker that subscribes to the time"
  [ scenario "the time passes as expected" (
      given (
        Subject.init ( testModel, Cmd.none )
          |> Subject.withUpdate testUpdate
          |> Subject.withSubscriptions testSubscriptions
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
        Subject.init ( testModel, Cmd.none )
          |> Subject.withUpdate testUpdate
          |> Subject.withSubscriptions testSubscriptions
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
      ( { model | count = model.count + 1, current = time }, Cmd.none )
    ReceivedZone zone ->
      ( { model | currentZone = zone }, Cmd.none )


type Msg
  = ReceivedTime Posix
  | ReceivedZone Zone


type alias Model =
  { count: Int
  , current: Posix
  , currentZone: Zone
  }


testModel =
  { count = 0
  , current = Time.millisToPosix 0
  , currentZone = Time.utc
  }


testSubscriptions : Model -> Sub Msg
testSubscriptions model =
  Time.every 1000 ReceivedTime


selectSpec : String -> Maybe (Spec Model Msg)
selectSpec name =
  case name of
    "stubTime" -> Just stubTimeSpec
    "stubZone" -> Just stubZoneSpec
    "interval" -> Just countTimePassingSpec
    _ -> Nothing


main =
  Runner.program selectSpec