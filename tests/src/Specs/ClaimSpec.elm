module Specs.ClaimSpec exposing (..)

import Spec exposing (..)
import Spec.Observer as Observer
import Spec.Setup as Setup
import Spec.Claim as Claim
import Specs.Helpers exposing (..)
import Runner


satisfyingSpec : Spec Model Msg
satisfyingSpec =
  Spec.describe "satisfying"
  [ scenario "all claims are satisfied" (
      given (
        specSetup
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
  , scenario "one claim fails" (
      given (
        specSetup
      )
      |> it "checks all the attributes of the model" (
        Observer.observeModel identity
          |> expect (
              Claim.satisfying
                [ \model -> equals "Cool Dude" model.name
                , \model -> equals "should fail" model.sport
                , \model -> equals 19 model.age
                ]
            )
      )
    )
  , scenario "multiple claims fail" (
      given (
        specSetup
      )
      |> it "checks all the attributes of the model" (
        Observer.observeModel identity
          |> expect (
              Claim.satisfying
                [ \model -> equals "Cool Dude" model.name
                , \model -> equals "should fail" model.sport
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
        specSetup
      )
      |> it "checks the value" (
        Observer.observeModel .isFun
          |> expect Claim.isTrue
      )
    )
  , scenario "false claim" (
      given (
        Setup.initWithModel { name = "Cool Dude", sport = "running", age = 19, isFun = False, possibly = Nothing }
      )
      |> it "checks the value" (
        Observer.observeModel .isFun
          |> expect Claim.isFalse
      )
    )
  , scenario "failing" (
      given (
        specSetup
      )
      |> it "checks the value" (
        Observer.observeModel .isFun
          |> expect Claim.isFalse
      )
    )
  ]


isSomethingWhereSpec : Spec Model Msg
isSomethingWhereSpec =
  Spec.describe "isSomethingWhere"
  [ scenario "is something where claim is accepted" (
      given (
        specSetupForMaybe <| Just "hello"
      )
      |> it "satisfies the claim" (
        Observer.observeModel .possibly
          |> expect (Claim.isSomethingWhere <| equals "hello")
      )
    )
  , scenario "is something where the claim is rejected" (
      given (
        specSetupForMaybe <| Just "hello"
      )
      |> it "rejects the claim" (
        Observer.observeModel .possibly
          |> expect (Claim.isSomethingWhere <| equals "blah")
      )
    )
  , scenario "nothing is found" (
      given (
        specSetupForMaybe Nothing
      )
      |> it "rejects the claim" (
        Observer.observeModel .possibly
          |> expect (Claim.isSomethingWhere <| equals "blah")
      )
    )
  ]


requireSpec : Spec Model Msg
requireSpec =
  Spec.describe "require"
  [ scenario "make a claim about part of a record" (
      given (
        specSetup
      )
      |> it "checks the value" (
        Observer.observeModel identity
          |> expect (Claim.require .name <| equals "Cool Dude")
      )
    )
  ]


specSetup =
  specSetupForMaybe Nothing


specSetupForMaybe maybeValue =
  Setup.initWithModel
    { name = "Cool Dude"
    , sport = "bowling"
    , age = 19
    , isFun = True
    , possibly = maybeValue
    }


type alias Model =
  { name: String
  , sport: String
  , age: Int
  , isFun: Bool
  , possibly: Maybe String
  }


type Msg =
  Msg


selectSpec : String -> Maybe (Spec Model Msg)
selectSpec specName =
  case specName of
    "satisfying" -> Just satisfyingSpec
    "boolean" -> Just booleanSpec
    "isSomethingWhere" -> Just isSomethingWhereSpec
    "require" -> Just requireSpec
    _ -> Nothing


main =
  Runner.program selectSpec