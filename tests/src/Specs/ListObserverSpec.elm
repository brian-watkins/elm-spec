module Specs.ListObserverSpec exposing (..)

import Spec exposing (Spec)
import Spec.Observer as Observer
import Spec.Subject as Subject
import Spec.Scenario exposing (..)
import Spec.Claim as Claim
import Runner


hasLengthSpec : Spec Model Msg
hasLengthSpec =
  Spec.describe "isListWithLength"
  [ scenario "the list has the expected length" (
      given (
        Subject.initWithModel [ "a", "b", "c" ]
      )
      |> it "has three items" (
        Observer.observeModel identity
          |> expect (Claim.isListWithLength 3)
      )
    )
  , scenario "the list does not have the expected length" (
      given (
        Subject.initWithModel [ "a" ]
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
        Subject.initWithModel [ "1", "2", "3", "4" ]
      )
      |> it "matches" (
        Observer.observeModel identity
          |> expect (
            Claim.isList
              [ Claim.isEqual "1"
              , Claim.isEqual "2"
              , Claim.isEqual "3"
              , Claim.isEqual "4"
              ]
          )
      )
    )
  , scenario "it has the correct size but some elements fail to match" (
      given (
        Subject.initWithModel [ "1", "2", "3", "4" ]
      )
      |> it "matches" (
        Observer.observeModel identity
          |> expect (
              Claim.isList
                [ Claim.isEqual "1"
                , Claim.isEqual "something"
                , Claim.isEqual "not correct"
                , Claim.isEqual "4"
                ]
          )
      )
    )
  , scenario "the list does not have the expected size" (
      given (
        Subject.initWithModel [ "1", "2", "3", "4" ]
      )
      |> it "matches" (
        Observer.observeModel identity
          |> expect (
            Claim.isList
              [ Claim.isEqual "1"
              , Claim.isEqual "3"
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
        Observer.observeModel identity
          |> expect (
            Claim.isListWhereIndex 2 (Claim.isEqual "3")
          )
      )
    )
  , scenario "the list has an element that does not match" (
      given (
        Subject.initWithModel [ "1", "2", "3", "4" ]
      )
      |> it "fails to match" (
        Observer.observeModel identity
          |> expect (
            Claim.isListWhereIndex 2 (Claim.isEqual "17")
          )
      )
    )
  , scenario "the list does not have an element at the index" (
      given (
        Subject.initWithModel [ "1", "2", "3", "4" ]
      )
      |> it "fails to match" (
        Observer.observeModel identity
          |> expect (
            Claim.isListWhereIndex 22 (Claim.isEqual "17")
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