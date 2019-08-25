module Specs.ExpectModelSpec exposing (..)

import Spec exposing (Spec(..))
import Spec.Actual as Actual
import Spec.Subject as Subject
import Spec.Observer as Observer
import Runner


failingSpec : Spec Model Msg
failingSpec =
  Spec.given "a fragment" (
    Subject.initWithModel { count = 99, name = "" }
      |> Subject.withUpdate testUpdate
  )
  |> Spec.it "fails" (
    Actual.model
      |> Actual.map .count
      |> Spec.expect (Observer.isEqual 17)
  )


passingSpec : Spec Model Msg
passingSpec =
  Spec.given "a fragment" (
    Subject.initWithModel { count = 99, name = "" }
      |> Subject.withUpdate testUpdate
  )
  |> Spec.it "contains the expected value" (
    Actual.model
      |> Actual.map .count
      |> Spec.expect (Observer.isEqual 99)
  )


multipleObservationsSpec : Spec Model Msg
multipleObservationsSpec =
  Spec.given "a fragment" (
    Subject.initWithModel { count = 87, name = "fun-spec" }
      |> Subject.withUpdate testUpdate
  )
  |> Spec.it "contains the expected number" (
    Actual.model
      |> Actual.map .count
      |> Spec.expect (Observer.isEqual 87)
  )
  |> Spec.it "contains the expected name" (
    Actual.model
      |> Actual.map .name
      |> Spec.expect (Observer.isEqual "awesome-spec")
  )


testUpdate : Msg -> Model -> ( Model, Cmd Msg )
testUpdate msg model =
  ( model, Cmd.none )


selectSpec : String -> Maybe (Spec Model Msg)
selectSpec specName =
  case specName of
    "failing" -> Just failingSpec
    "passing" -> Just passingSpec
    "multiple" -> Just multipleObservationsSpec
    _ -> Nothing


type Msg
  = Msg


type alias Model =
  { count: Int
  , name: String
  }


main =
  Runner.program selectSpec