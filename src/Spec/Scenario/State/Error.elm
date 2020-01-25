module Spec.Scenario.State.Error exposing
  ( init
  )

import Spec.Scenario.State as State exposing (Actions, Msg(..))
import Spec.Report exposing (Report)


init : Actions msg programMsg -> List String -> String -> Report -> ( State.Model model programMsg, Cmd msg )
init actions conditions description report =
  ( initModel
  , State.abortWith actions conditions description report
  )


initModel : State.Model model programMsg
initModel =
  State.Running 
    { update = update
    , view = Nothing
    , subscriptions = Nothing
    }


update : Actions msg programMsg -> State.Msg programMsg -> ( State.Model model programMsg, Cmd msg )
update actions msg =
  ( initModel, actions.complete )
