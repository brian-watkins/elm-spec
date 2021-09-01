module Harness.Types exposing (..)

import Json.Decode as Json
import Spec.Observer.Internal as Observer
import Spec.Step exposing (Step)
import Spec.Setup exposing (Setup)
import Spec.Report exposing (Report)


type HarnessFunction model msg
  = SetupFunction (Json.Value -> Result Report (Setup model msg))
  | StepsFunction (Json.Value -> Result Report (List (Step model msg)))
  | ExpectationFunction (Json.Value -> Result Report (Expectation model))


type alias ExposedExpectation model =
  Json.Value -> Result Report (Expectation model)


type alias ExposedSteps model msg
  = Json.Value -> Result Report (List (Step model msg))


type alias ExposedSetup model msg =
  Json.Value -> Result Report (Setup model msg)

type Expectation model =
  Expectation
    (Observer.Expectation model)
