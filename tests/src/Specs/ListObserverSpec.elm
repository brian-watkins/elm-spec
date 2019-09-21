module Specs.ListObserverSpec exposing (..)

import Spec exposing (Spec)
import Spec.Observation as Observation
import Spec.Subject as Subject
import Spec.Scenario exposing (..)
import Spec.Observer as Observer
import Runner


hasLengthSpec : Spec Model Msg
hasLengthSpec =
  Spec.describe "isListWithLength"
  [ scenario "the list has the expected length" (
      Subject.initWithModel [ "a", "b", "c" ]
    )
    |> it "has three items" (
      Observation.selectModel
        |> Observation.expect (Observer.isListWithLength 3)
    )
  , scenario "the list does not have the expected length" (
      Subject.initWithModel [ "a" ]
    )
    |> it "has three items" (
      Observation.selectModel
        |> Observation.expect (Observer.isListWithLength 3)
    )
  ]


isListSpec : Spec Model Msg
isListSpec =
  Spec.describe "isList"
  [ scenario "the list matches" (
      Subject.initWithModel [ "1", "2", "3", "4" ]
    )
    |> it "matches" (
      Observation.selectModel
        |> Observation.expect (
          Observer.isList
            [ Observer.isEqual "1"
            , Observer.isEqual "2"
            , Observer.isEqual "3"
            , Observer.isEqual "4"
            ]
        )
    )
  , scenario "it has the correct size but some elements fail to match" (
      Subject.initWithModel [ "1", "2", "3", "4" ]
    )
    |> it "matches" (
      Observation.selectModel
        |> Observation.expect (
            Observer.isList
              [ Observer.isEqual "1"
              , Observer.isEqual "something"
              , Observer.isEqual "not correct"
              , Observer.isEqual "4"
              ]
        )
    )
  , scenario "the list does not have the expected size" (
      Subject.initWithModel [ "1", "2", "3", "4" ]
    )
    |> it "matches" (
      Observation.selectModel
        |> Observation.expect (
          Observer.isList
            [ Observer.isEqual "1"
            , Observer.isEqual "3"
            ]
        )
    )
  ]


type alias Model =
  List String

type Msg =
  Msg


selectSpec : String -> Maybe (Spec Model Msg)
selectSpec specName =
  case specName of
    "isListWithLength" -> Just hasLengthSpec
    "isList" -> Just isListSpec
    _ -> Nothing


main =
  Runner.program selectSpec