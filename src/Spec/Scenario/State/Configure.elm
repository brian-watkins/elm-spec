module Spec.Scenario.State.Configure exposing
  ( Model
  , init
  , update
  )

import Spec.Scenario.Internal exposing (Scenario)
import Spec.Setup.Internal exposing (Subject)
import Spec.Scenario.State as State exposing (Msg(..), Command, Actions)
import Spec.Message as Message
import Spec.Scenario.Message as Message
import Spec.Report as Report exposing (Report)
import Spec.Message exposing (Message)


type alias Model model msg =
  { scenario: Scenario model msg
  , subject: Subject model msg
  }


init : Scenario model programMsg -> Subject model programMsg -> Model model programMsg
init scenario subject =
  { scenario = scenario
  , subject = subject
  }


update : Actions msg programMsg -> Msg programMsg -> Model model programMsg -> ( Model model programMsg, Command msg )
update actions msg model =
  case msg of
    ReceivedMessage message ->
      if Message.is "_configure" "complete" message then
        ( model, State.Transition <| State.continue actions )
      else
        ( model
        , abortWith actions model <| Report.note "Unknown message received!"
        )
    Continue ->
      ( model, configureWith actions model.subject.configureEnvironment )
    Abort report ->
      ( model
      , abortWith actions model report
      )
    _ ->
      ( model
      , abortWith actions model <| Report.note "Unknown state!"
      )


configureWith : Actions msg programMsg -> List Message -> Command msg
configureWith actions configMessages =
  if List.isEmpty configMessages then
    State.send actions Message.configureComplete
  else
    List.map Message.configMessage configMessages
      |> State.sendMany actions


abortWith : Actions msg programMsg -> Model model programMsg -> Report -> Command msg
abortWith actions model report =
  State.abortWith actions
    [ model.scenario.specification
    , model.scenario.description
    ] 
    "Unable to configure scenario"
    report
