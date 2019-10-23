module Specs.ObserverSpec exposing (..)

import Spec exposing (Spec)
import Spec.Observation as Observation
import Spec.Subject as Subject
import Spec.Scenario exposing (..)
import Spec.Claim as Claim
import Runner


satisfyingSpec : Spec Model Msg
satisfyingSpec =
  Spec.describe "satisfying"
  [ scenario "all observers are satisfied" (
      given (
        Subject.initWithModel { name = "Cool Dude", sport = "bowling", age = 19 }
      )
      |> it "checks all the attributes of the model" (
        Observation.selectModel identity
          |> expect (
              Claim.satisfying
                [ \model -> Claim.isEqual "Cool Dude" model.name
                , \model -> Claim.isEqual "bowling" model.sport
                , \model -> Claim.isEqual 19 model.age
                ]
            )
      )
    )
  , scenario "one observer fails" (
      given (
        Subject.initWithModel { name = "Cool Dude", sport = "running", age = 19 }
      )
      |> it "checks all the attributes of the model" (
        Observation.selectModel identity
          |> expect (
              Claim.satisfying
                [ \model -> Claim.isEqual "Cool Dude" model.name
                , \model -> Claim.isEqual "bowling" model.sport
                , \model -> Claim.isEqual 19 model.age
                ]
            )
      )
    )
  , scenario "multiple observers fail" (
      given (
        Subject.initWithModel { name = "Cool Dude", sport = "running", age = 19 }
      )
      |> it "checks all the attributes of the model" (
        Observation.selectModel identity
          |> expect (
              Claim.satisfying
                [ \model -> Claim.isEqual "Cool Dude" model.name
                , \model -> Claim.isEqual "bowling" model.sport
                , \model -> Claim.isEqual 27 model.age
                ]
            )
      )
    )
  ]


type alias Model =
  { name: String
  , sport: String
  , age: Int
  }


type Msg =
  Msg


selectSpec : String -> Maybe (Spec Model Msg)
selectSpec specName =
  case specName of
    "satisfying" -> Just satisfyingSpec
    _ -> Nothing


main =
  Runner.program selectSpec