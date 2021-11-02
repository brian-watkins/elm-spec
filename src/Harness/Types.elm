module Harness.Types exposing
  ( Definition(..)
  , Expectation(..)
  , Harness
  , HarnessError
  , HarnessFunction
  )

import Json.Decode as Json
import Spec.Observer.Internal as Observer
import Spec.Step exposing (Step)
import Spec.Setup exposing (Setup)


type alias HarnessError =
  String

type alias HarnessFunction b =
  Json.Value -> Result HarnessError b


type Expectation model =
  Expectation
    (Observer.Expectation model)


type Definition b
  = Definition String (Json.Value -> Result String b)


type alias Harness model msg =
  { initialStates: List (Definition (Setup model msg))
  , scripts: List (Definition (List (Step model msg)))
  , expectations: List (Definition (Expectation model))
  }
