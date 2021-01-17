module Specs.ListObserverSpec exposing (..)

import Spec exposing (..)
import Spec.Observer as Observer
import Spec.Setup as Setup
import Spec.Claim as Claim
import Runner
import Specs.Helpers exposing (..)


hasLengthSpec : Spec Model Msg
hasLengthSpec =
  Spec.describe "isListWithLength"
  [ scenario "the list has the expected length" (
      given (
        Setup.initWithModel [ "a", "b", "c" ]
      )
      |> it "has three items" (
        Observer.observeModel identity
          |> expect (Claim.isListWithLength 3)
      )
    )
  , scenario "the list does not have the expected length" (
      given (
        Setup.initWithModel [ "a" ]
      )
      |> it "has three items" (
        Observer.observeModel identity
          |> expect (Claim.isListWithLength 3)
      )
    )
  ]


isListSpec : Spec Model Msg
isListSpec =
  Spec.describe "isList"
  [ scenario "the list matches" (
      given (
        Setup.initWithModel [ "1", "2", "3", "4" ]
      )
      |> it "matches" (
        Observer.observeModel identity
          |> expect (
            Claim.isListWhere
              [ equals "1"
              , equals "2"
              , equals "3"
              , equals "4"
              ]
          )
      )
    )
  , scenario "it has the correct size but some elements fail to match" (
      given (
        Setup.initWithModel [ "1", "2", "3", "4" ]
      )
      |> it "matches" (
        Observer.observeModel identity
          |> expect (
              Claim.isListWhere
                [ equals "1"
                , equals "something"
                , equals "not correct"
                , equals "4"
                ]
          )
      )
    )
  , scenario "the list does not have the expected size" (
      given (
        Setup.initWithModel [ "1", "2", "3", "4" ]
      )
      |> it "matches" (
        Observer.observeModel identity
          |> expect (
            Claim.isListWhere
              [ equals "1"
              , equals "3"
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
        Setup.initWithModel [ "1", "2", "3", "4" ]
      )
      |> it "matches" (
        Observer.observeModel identity
          |> expect (
            Claim.isListWhereItemAt 2 (equals "3")
          )
      )
    )
  , scenario "the list has an element that does not match" (
      given (
        Setup.initWithModel [ "1", "2", "3", "4" ]
      )
      |> it "fails to match" (
        Observer.observeModel identity
          |> expect (
            Claim.isListWhereItemAt 2 (equals "17")
          )
      )
    )
  , scenario "the list does not have an element at the index" (
      given (
        Setup.initWithModel [ "1", "2", "3", "4" ]
      )
      |> it "fails to match" (
        Observer.observeModel identity
          |> expect (
            Claim.isListWhereItemAt 22 (equals "17")
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