module Spec.Scenario.State.Start exposing
  ( Model
  , init
  , update
  )

import Spec.Scenario.State as State exposing (Msg(..), Actions)
import Spec.Setup.Internal as Internal exposing (Subject)
import Spec.Scenario.Internal as Internal exposing (Scenario)


type alias Model model msg =
  { scenario: Scenario model msg
  , subject: Subject model msg
  }


init : Scenario model msg -> Subject model msg -> Model model msg
init scenario subject =
  { scenario = scenario
  , subject = subject
  }


update : Actions msg programMsg -> State.Msg programMsg -> Model model programMsg -> ( Model model programMsg, State.Command msg )
update actions msg model =
  case msg of
    Continue ->
      ( model, State.Transition <| State.continue actions )
    _ ->
      ( model, State.Halt Cmd.none )