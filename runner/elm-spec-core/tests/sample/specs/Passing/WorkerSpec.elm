module Passing.WorkerSpec exposing (main)

import Spec exposing (..)
import Spec.Setup as Setup
import Spec.Observer as Observer
import Spec.Claim as Claim exposing (Claim)
import Runner


funSpec : Spec Model Msg
funSpec =
  Spec.describe "something fun"
  [ scenario "something passes" (
      given (
        Setup.initWithModel { value = 87 }
      )
      |> it "passes" (
        Observer.observeModel .value
          |> expect (equals 87)
      )
    )
  ]


awesomeSpec : Spec Model Msg
awesomeSpec =
  Spec.describe "something awesome"
  [ scenario "something passes" (
      given (
        Setup.initWithModel { value = 91 }
      )
      |> it "passes" (
        Observer.observeModel .value
          |> expect (equals 91)
      )
    )
  ]


type Msg
  = Msg


type alias Model =
  { value: Int
  }


equals : a -> Claim a
equals =
  Claim.isEqual Debug.toString


main =
  Runner.workerProgram
    [ funSpec
    , awesomeSpec
    ]