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
      given (
        Subject.initWithModel [ "a", "b", "c" ]
      )
      |> it "has three items" (
        Observation.selectModel identity
          |> expect (Observer.isListWithLength 3)
      )
    )
  , scenario "the list does not have the expected length" (
      given (
        Subject.initWithModel [ "a" ]
      )
      |> it "has three items" (
        Observation.selectModel identity
          |> expect (Observer.isListWithLength 3)
      )
    )
  ]


isListSpec : Spec Model Msg
isListSpec =
  Spec.describe "isList"
  [ scenario "the list matches" (
      given (
        Subject.initWithModel [ "1", "2", "3", "4" ]
      )
      |> it "matches" (
        Observation.selectModel identity
          |> expect (
            Observer.isList
              [ Observer.isEqual "1"
              , Observer.isEqual "2"
              , Observer.isEqual "3"
              , Observer.isEqual "4"
              ]
          )
      )
    )
  , scenario "it has the correct size but some elements fail to match" (
      given (
        Subject.initWithModel [ "1", "2", "3", "4" ]
      )
      |> it "matches" (
        Observation.selectModel identity
          |> expect (
              Observer.isList
                [ Observer.isEqual "1"
                , Observer.isEqual "something"
                , Observer.isEqual "not correct"
                , Observer.isEqual "4"
                ]
          )
      )
    )
  , scenario "the list does not have the expected size" (
      given (
        Subject.initWithModel [ "1", "2", "3", "4" ]
      )
      |> it "matches" (
        Observation.selectModel identity
          |> expect (
            Observer.isList
              [ Observer.isEqual "1"
              , Observer.isEqual "3"
              ]
          )
      )
    )
  ]


atIndexSpec : Spec Model Msg
atIndexSpec =
  Spec.describe "atIndex"
  [ scenario "the list has an element that matches" (
      given (
        Subject.initWithModel [ "1", "2", "3", "4" ]
      )
      |> it "matches" (
        Observation.selectModel identity
          |> expect (
            Observer.isListWhereIndex 2 (Observer.isEqual "3")
          )
      )
    )
  , scenario "the list has an element that does not match" (
      given (
        Subject.initWithModel [ "1", "2", "3", "4" ]
      )
      |> it "fails to match" (
        Observation.selectModel identity
          |> expect (
            Observer.isListWhereIndex 2 (Observer.isEqual "17")
          )
      )
    )
  , scenario "the list does not have an element at the index" (
      given (
        Subject.initWithModel [ "1", "2", "3", "4" ]
      )
      |> it "fails to match" (
        Observation.selectModel identity
          |> expect (
            Observer.isListWhereIndex 22 (Observer.isEqual "17")
          )
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
    "atIndex" -> Just atIndexSpec
    _ -> Nothing


main =
  Runner.program selectSpec