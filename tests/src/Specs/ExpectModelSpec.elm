module Specs.ExpectModelSpec exposing (..)

import Spec exposing (Spec(..))
import Spec.Observer as Observer
import Spec.Subject as Subject
import Spec.Scenario exposing (..)
import Spec.Claim as Claim
import Runner


failingSpec : Spec Model Msg
failingSpec =
  Spec.describe "a fragment"
  [ scenario "failing observation" (
      given (
        Subject.initWithModel { count = 99, name = "" }
          |> Subject.withUpdate testUpdate
      )
      |> it "fails" (
        Observer.observeModel .count
          |> expect (Claim.isEqual 17)
      )
    )
  ]


passingSpec : Spec Model Msg
passingSpec =
  Spec.describe "a fragment"
  [ scenario "a valid observation" (
      given (
        Subject.initWithModel { count = 99, name = "" }
          |> Subject.withUpdate testUpdate
      )
      |> it "contains the expected value" (
        Observer.observeModel .count
          |> expect (Claim.isEqual 99)
      )
    )
  ]


multipleObservationsSpec : Spec Model Msg
multipleObservationsSpec =
  Spec.describe "a fragment"
  [ scenario "multiple observations" (
      given (
        Subject.initWithModel { count = 87, name = "fun-spec" }
          |> Subject.withUpdate testUpdate
      )
      |> observeThat
        [ it "contains the expected number" (
            Observer.observeModel .count
              |> expect (Claim.isEqual 87)
          )
        , it "contains the expected name" (
            Observer.observeModel .name
              |> expect (Claim.isEqual "awesome-spec")
          )
        ]
    )
  ]


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