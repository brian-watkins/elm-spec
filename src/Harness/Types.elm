module Harness.Types exposing (..)

import Json.Decode as Json
import Spec.Observer.Internal as Observer
import Spec.Step exposing (Step)
import Spec.Setup exposing (Setup)


type alias ExposedExpectation model =
  Json.Value -> Expectation model


type alias ExposedSteps model msg
  = List (Step model msg)


type alias ExposedSetup model msg =
  Json.Value -> Setup model msg

type Expectation model =
  Expectation
    (Observer.Expectation model)
