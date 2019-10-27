module Specs.ObserverSpec exposing (..)

import Spec exposing (Spec)
import Spec.Observer as Observer
import Spec.Subject as Subject
import Spec.Scenario exposing (..)
import Spec.Claim as Claim
import Specs.Helpers exposing (..)
import Runner


satisfyingSpec : Spec Model Msg
satisfyingSpec =
  Spec.describe "satisfying"
  [ scenario "all observers are satisfied" (
      given (
        Subject.initWithModel { name = "Cool Dude", sport = "bowling", age = 19, isFun = True }
      )
      |> it "checks all the attributes of the model" (
        Observer.observeModel identity
          |> expect (
              Claim.satisfying
                [ \model -> equals "Cool Dude" model.name
                , \model -> equals "bowling" model.sport
                , \model -> equals 19 model.age
                ]
            )
      )
    )
  , scenario "one observer fails" (
      given (
        Subject.initWithModel { name = "Cool Dude", sport = "running", age = 19, isFun = True }
      )
      |> it "checks all the attributes of the model" (
        Observer.observeModel identity
          |> expect (
              Claim.satisfying
                [ \model -> equals "Cool Dude" model.name
                , \model -> equals "bowling" model.sport
                , \model -> equals 19 model.age
                ]
            )
      )
    )
  , scenario "multiple observers fail" (
      given (
        Subject.initWithModel { name = "Cool Dude", sport = "running", age = 19, isFun = True }
      )
      |> it "checks all the attributes of the model" (
        Observer.observeModel identity
          |> expect (
              Claim.satisfying
                [ \model -> equals "Cool Dude" model.name
                , \model -> equals "bowling" model.sport
                , \model -> equals 27 model.age
                ]
            )
      )
    )
  ]


booleanSpec : Spec Model Msg
booleanSpec =
  Spec.describe "boolean claims"
  [ scenario "true claim" (
      given (
        Subject.initWithModel { name = "Cool Dude", sport = "running", age = 19, isFun = True }
      )
      |> it "checks the value" (
        Observer.observeModel .isFun
          |> expect Claim.isTrue
      )
    )
  , scenario "false claim" (
      given (
        Subject.initWithModel { name = "Cool Dude", sport = "running", age = 19, isFun = False }
      )
      |> it "checks the value" (
        Observer.observeModel .isFun
          |> expect Claim.isFalse
      )
    )
  , scenario "failing" (
      given (
        Subject.initWithModel { name = "Cool Dude", sport = "running", age = 19, isFun = True }
      )
      |> it "checks the value" (
        Observer.observeModel .isFun
          |> expect Claim.isFalse
      )
    )
  ]


type alias Model =
  { name: String
  , sport: String
  , age: Int
  , isFun: Bool
  }


type Msg =
  Msg


selectSpec : String -> Maybe (Spec Model Msg)
selectSpec specName =
  case specName of
    "satisfying" -> Just satisfyingSpec
    "boolean" -> Just booleanSpec
    _ -> Nothing


main =
  Runner.program selectSpec