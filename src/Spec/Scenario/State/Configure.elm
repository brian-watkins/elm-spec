module Spec.Scenario.State.Configure exposing
  ( Model
  , init
  , update
  )

import Spec.Scenario.Internal exposing (Scenario)
import Spec.Setup.Internal exposing (Subject)
import Spec.Scenario.State as State exposing (Msg(..), Command, Actions)
import Spec.Scenario.Message as Message
import Spec.Message exposing (Message)


type alias Model model msg =
  { scenario: Scenario model msg
  , subject: Subject model msg
  }


init : Actions msg programMsg -> Scenario model programMsg -> Subject model programMsg -> ( Model model programMsg, Command msg )
init actions scenario subject =
  ( { scenario = scenario
    , subject = subject
    }
  , configureWith actions subject.configureEnvironment
  )


configureWith : Actions msg programMsg -> List Message -> Command msg
configureWith actions configMessages =
  if List.isEmpty configMessages then
    State.send actions Message.configureComplete
  else
    List.map Message.configMessage configMessages
      |> State.sendMany actions


update : Actions msg programMsg -> Msg programMsg -> Model model programMsg -> ( Model model programMsg, Command msg )
update actions msg model =
  case msg of
    Continue ->
      ( model, State.Transition <| State.continue actions )
    Abort report ->
      ( model
      , State.abortWith actions
          [ model.scenario.specification, model.scenario.description ] "Unable to configure scenario" report
      )
    _ ->
      ( model, State.Do Cmd.none )