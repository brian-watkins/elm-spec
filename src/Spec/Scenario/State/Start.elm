module Spec.Scenario.State.Start exposing
  ( init
  )

import Spec.Scenario.State as State exposing (Msg(..), Actions)
import Spec.Setup.Internal exposing (Subject)
import Spec.Scenario.Internal exposing (Scenario)
import Spec.Message as Message
import Spec.Step.Message as Message
import Spec.Scenario.Message as Message
import Spec.Report as Report
import Spec.Scenario.State.Error as Error
import Spec.Scenario.State.Configure as Configure


type alias Model model msg =
  { scenario: Scenario model msg
  , subject: Subject model msg
  }


init : Actions msg programMsg -> Scenario model programMsg -> Subject model programMsg -> ( State.Model msg programMsg, Cmd msg )
init actions scenario subject =
  ( start <| initModel scenario subject
  , State.send actions Message.startScenario
  )


start : Model model programMsg -> State.Model msg programMsg
start model =
  State.Running
    { update = update model
    , view = Nothing
    , subscriptions = Nothing
    }


initModel : Scenario model msg -> Subject model msg -> Model model msg
initModel scenario subject =
  { scenario = scenario
  , subject = subject
  }


update : Model model programMsg -> Actions msg programMsg -> State.Msg programMsg -> ( State.Model msg programMsg, Cmd msg )
update model actions msg =
  case msg of
    ReceivedMessage message ->
      if Message.is "start" "flush-animation-tasks" message then
        ( start model
        , actions.send Message.runToNextAnimationFrame
        )
      else
        ( start model, Cmd.none )
    Continue ->
      Configure.init actions model.scenario model.subject
    ProgramMsg _ ->
      ( start model
      , actions.send Message.stepComplete
      )
    _ ->
      Report.note "Unknown message for start state!"
        |> Error.init actions [] "Scenario Failed"
