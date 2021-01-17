module Specs.ExpectModelSpec exposing (..)

import Spec exposing (..)
import Spec.Observer as Observer
import Spec.Setup as Setup
import Spec.Claim as Claim
import Runner
import Specs.Helpers exposing (..)


failingSpec : Spec Model Msg
failingSpec =
  Spec.describe "a fragment"
  [ scenario "failing observation" (
      given (
        Setup.initWithModel { count = 99, name = "" }
          |> Setup.withUpdate testUpdate
      )
      |> it "fails" (
        Observer.observeModel .count
          |> expect (equals 17)
      )
    )
  ]


passingSpec : Spec Model Msg
passingSpec =
  Spec.describe "a fragment"
  [ scenario "a valid observation" (
      given (
        Setup.initWithModel { count = 99, name = "" }
          |> Setup.withUpdate testUpdate
      )
      |> it "contains the expected value" (
        Observer.observeModel .count
          |> expect (equals 99)
      )
    )
  ]


multipleObservationsSpec : Spec Model Msg
multipleObservationsSpec =
  Spec.describe "a fragment"
  [ scenario "multiple observations" (
      given (
        Setup.initWithModel { count = 87, name = "fun-spec" }
          |> Setup.withUpdate testUpdate
      )
      |> observeThat
        [ it "contains the expected number" (
            Observer.observeModel .count
              |> expect (equals 87)
          )
        , it "contains the expected name" (
            Observer.observeModel .name
              |> expect (equals "awesome-spec")
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