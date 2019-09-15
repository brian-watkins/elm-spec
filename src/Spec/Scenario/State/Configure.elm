module Spec.Scenario.State.Configure exposing
  ( Model
  , init
  )

import Spec.Scenario exposing (Scenario)
import Spec.Scenario.State as State exposing (Msg(..), Command)
import Spec.Scenario.Message as Message


type alias Model model msg =
  { scenario: Scenario model msg
  }


init : Scenario model msg -> ( Model model msg, Command msg )
init scenario =
  ( { scenario = scenario }
  , List.append scenario.subject.configureEnvironment [ Message.configureComplete ]
      |> State.SendMany
  )