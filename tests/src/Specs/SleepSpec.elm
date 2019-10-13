port module Specs.SleepSpec exposing (..)

import Spec exposing (Spec)
import Spec.Subject as Subject
import Spec.Scenario exposing (..)
import Spec.Port as Port
import Spec.Observer as Observer
import Spec.Observation as Observation
import Spec.Time as Time
import Runner
import Json.Encode as Encode
import Task
import Process


processSpec : Spec Model Msg
processSpec =
  Spec.describe "a program that uses Process.sleep"
  [ scenario "the program stores up sleeps and processes them when time passes" (
      given (
        Subject.init ( { items = [] }, Cmd.none )
          |> Subject.withUpdate testUpdate
          |> Subject.withSubscriptions testSubscriptions
          |> Time.fake
      )
      |> when "subscription messages are received"
        [ Port.send "processSub" (Encode.string "a")
        , Port.send "processSub" (Encode.string "b")
        , Port.send "processSub" (Encode.string "c")
        , Time.tick 100
        , Time.tick 100
        , Time.tick 100
        ]
      |> it "receives the delayed messages" (
        Observation.selectModel
          |> Observation.mapSelection .items
          |> Observation.expect (Observer.isEqual [ "c", "b", "a", "Hey", "Hey", "Hey" ])
      )
    )
  ]

processOnlyUpToDelaySpec : Spec Model Msg
processOnlyUpToDelaySpec =
  Spec.describe "a program that uses Process.sleep"
  [ scenario "not enough time passes for everything" (
      given (
        Subject.init ( { items = [] }, Cmd.none )
          |> Subject.withUpdate testDelayUpdate
          |> Subject.withSubscriptions testSubscriptions
          |> Time.fake
      )
      |> when "subscription messages are received"
        [ Port.send "processSub" (Encode.string "a")
        , Time.tick 100
        , Port.send "processSub" (Encode.string "b")
        , Time.tick 50
        ]
      |> it "receives the expected messages only" (
        Observation.selectModel
          |> Observation.mapSelection .items
          |> Observation.expect (Observer.isEqual [ "Hey", "a", "Hey" ])
      )
    )
  ]


testDelayUpdate : Msg -> Model -> ( Model, Cmd Msg )
testDelayUpdate msg model =
  case msg of
    ReceivedMessage message ->
      ( model
      , Cmd.batch
        [ Process.sleep 100
            |> Task.andThen (\_ -> Task.succeed message)
            |> Task.perform DoSomething
        , Task.succeed "Hey"
            |> Task.perform DoSomething 
        ]
      )
    DoSomething message ->
      ( { model | items = message :: model.items }, Cmd.none )


testUpdate : Msg -> Model -> ( Model, Cmd Msg )
testUpdate msg model =
  case msg of
    ReceivedMessage message ->
      ( model
      , Cmd.batch
        [ Process.sleep (100 * (toFloat <| 1 + List.length model.items))
            |> Task.andThen (\_ -> Task.succeed message)
            |> Task.perform DoSomething
        , Task.succeed "Hey"
            |> Task.perform DoSomething 
        ]
      )
    DoSomething message ->
      ( { model | items = message :: model.items }, Cmd.none )


selectSpec : String -> Maybe (Spec Model Msg)
selectSpec name =
  case name of
    "sleep" -> Just processSpec
    "delay" -> Just processOnlyUpToDelaySpec
    _ -> Nothing


type Msg
  = ReceivedMessage String
  | DoSomething String


type alias Model =
  { items: List String
  }


port processSub : (String -> msg) -> Sub msg


testSubscriptions : Model -> Sub Msg
testSubscriptions model =
  processSub ReceivedMessage


main =
  Runner.program selectSpec