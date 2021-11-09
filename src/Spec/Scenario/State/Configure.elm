module Spec.Scenario.State.Configure exposing
  ( init
  )

import Spec.Scenario.Internal exposing (Scenario)
import Spec.Setup.Internal exposing (Subject, Configuration(..))
import Spec.Setup.Message as Message
import Spec.Scenario.State as State exposing (Msg(..), Actions)
import Spec.Message as Message
import Spec.Scenario.Message as Message
import Spec.Report as Report exposing (Report)
import Spec.Scenario.State.Exercise as Exercise
import Spec.Scenario.State.Error as Error


type alias Model model msg =
  { scenario: Scenario model msg
  , subject: Subject model msg
  , configurations: List Configuration
  }


init : Actions msg programMsg -> Scenario model programMsg -> Subject model programMsg -> (State.Model msg programMsg, Cmd msg)
init actions scenario subject =
  ( configure <| initModel scenario subject
  , State.continue actions
  )


initModel : Scenario model programMsg -> Subject model programMsg -> Model model programMsg
initModel scenario subject =
  { scenario = scenario
  , subject = subject
  , configurations = subject.configurations
  }


configure : Model model programMsg -> State.Model msg programMsg
configure model =
  State.Running
    { update = update model
    , view = Nothing
    , subscriptions = Nothing
    }


update : Model model programMsg -> Actions msg programMsg -> State.Msg programMsg -> ( State.Model msg programMsg, Cmd msg )
update configModel actions msg =
  case msg of
    Continue ->
      case configModel.configurations of
        [] ->
          Exercise.init actions configModel.scenario configModel.subject
        configuration :: remaining ->
          case configuration of
            ConfigCommand message ->
              ( configure { configModel | configurations = remaining }
              , State.send actions <| Message.configCommandMessage message
              )
            ConfigRequest message ->
              ( configure { configModel | configurations = remaining }
              , State.send actions <| Message.configRequestMessage message
              )
    Abort report ->
      abortWith actions configModel report
    _ ->
      Report.note "Unknown configure state!"
        |> abortWith actions configModel


abortWith : Actions msg programMsg -> Model model programMsg -> Report -> (State.Model msg programMsg, Cmd msg)
abortWith actions configModel report =
  Error.init actions
    [ configModel.scenario.specification
    , configModel.scenario.description
    ]
    "Unable to configure scenario"
    report
