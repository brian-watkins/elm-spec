module Spec.Scenario.State.Start exposing
  ( init
  )

import Spec.Scenario.State as State exposing (Msg(..), Actions)
import Spec.Setup.Internal as Internal exposing (Subject)
import Spec.Scenario.Internal as Internal exposing (Scenario)
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
  ( State.Running
    { update = update <| initModel scenario subject
    , view = Nothing
    , subscriptions = Nothing
    }
  , State.send actions Message.startScenario
  )


initModel : Scenario model msg -> Subject model msg -> Model model msg
initModel scenario subject =
  { scenario = scenario
  , subject = subject
  }


update : Model model programMsg -> Actions msg programMsg -> State.Msg programMsg -> ( State.Model msg programMsg, Cmd msg )
update startModel actions msg =
  case msg of
    Continue ->
      Configure.init actions startModel.scenario startModel.subject
    _ ->
      Report.note "Unknown scenario state!"
        |> Error.init actions [] "Scenario Failed"
