module Specs.ListObserverSpec exposing (..)

import Spec exposing (Spec)
import Spec.Observation as Observation
import Spec.Subject as Subject
import Spec.Scenario exposing (..)
import Spec.Observer as Observer
import Runner


hasLengthSpec : Spec Model Msg
hasLengthSpec =
  Spec.describe "hasLength"
  [ scenario "the list has the expected length" (
      Subject.initWithModel [ "a", "b", "c" ]
    )
    |> it "has three items" (
      Observation.selectModel
        |> Observation.expect (Observer.hasLength 3)
    )
  , scenario "the list does not have the expected length" (
      Subject.initWithModel [ "a" ]
    )
    |> it "has three items" (
      Observation.selectModel
        |> Observation.expect (Observer.hasLength 3)
    )
  ]

type alias Model =
  List String

type Msg =
  Msg


selectSpec : String -> Maybe (Spec Model Msg)
selectSpec specName =
  case specName of
    "hasLength" -> Just hasLengthSpec
    _ -> Nothing


main =
  Runner.program selectSpec