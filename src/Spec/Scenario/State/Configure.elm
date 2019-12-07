module Spec.Scenario.State.Configure exposing
  ( Model
  , init
  )

import Spec.Scenario.Internal exposing (Scenario)
import Spec.Setup.Internal exposing (Subject)
import Spec.Scenario.State as State exposing (Msg(..), Command)
import Spec.Scenario.Message as Message


type alias Model model msg =
  { scenario: Scenario model msg
  , subject: Subject model msg
  }


init : Scenario model msg -> Subject model msg -> ( Model model msg, Command msg )
init scenario subject =
  ( { scenario = scenario
    , subject = subject
    }
  , List.append subject.configureEnvironment [ Message.configureComplete ]
      |> State.SendMany
  )