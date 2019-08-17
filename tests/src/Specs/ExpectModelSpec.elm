module Specs.ExpectModelSpec exposing (..)

import Spec exposing (Spec(..))
import Spec.Subject as Subject
import Spec.Observer as Observer
import Spec.Context as Context
import Runner


failingSpec : Spec Model Msg
failingSpec =
  Spec.given "a fragment" (
    Subject.initWithModel { count = 99, name = "" }
      |> Subject.withUpdate testUpdate
  )
  |> Spec.it "fails" (
    Context.expectModel <|
      \model ->
        Observer.isEqual 17 model.count
  )


passingSpec : Spec Model Msg
passingSpec =
  Spec.given "a fragment" (
    Subject.initWithModel { count = 99, name = "" }
      |> Subject.withUpdate testUpdate
  )
  |> Spec.it "contains the expected value" (
      Context.expectModel <|
        \model ->
          Observer.isEqual 99 model.count
  )


multipleObservationsSpec : Spec Model Msg
multipleObservationsSpec =
  Spec.given "a fragment" (
    Subject.initWithModel { count = 87, name = "fun-spec" }
      |> Subject.withUpdate testUpdate
  )
  |> Spec.it "contains the expected number" ( Context.expectModel <|
      \model ->
        Observer.isEqual 87 model.count
  )
  |> Spec.it "contains the expected name" ( Context.expectModel <|
      \model ->
        Observer.isEqual "awesome-spec" model.name
  )


testUpdate : Msg -> Model -> ( Model, Cmd Msg )
testUpdate msg model =
  ( model, Cmd.none )


selectSpec : String -> Spec Model Msg
selectSpec specName =
  case specName of
    "failing" ->
      failingSpec
    "passing" ->
      passingSpec
    "multiple" ->
      multipleObservationsSpec
    _ ->
      failingSpec


type Msg
  = Msg


type alias Model =
  { count: Int
  , name: String
  }


main =
  Runner.program selectSpec