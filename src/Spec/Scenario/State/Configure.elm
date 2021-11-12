module Spec.Scenario.State.Configure exposing
  ( init
  )

import Spec.Scenario.Internal exposing (Scenario)
import Spec.Setup.Internal as Setup exposing (Subject, Configuration(..))
import Spec.Setup.Message as Message
import Spec.Scenario.State as State exposing (Msg(..), Actions)
import Spec.Message as Message exposing (Message)
import Spec.Message.Internal as Message
import Spec.Scenario.Message as Message
import Spec.Report as Report exposing (Report)
import Spec.Scenario.State.Exercise as Exercise
import Spec.Scenario.State.Error as Error


type alias Model model msg =
  { scenario: Scenario model msg
  , subject: Subject model msg
  , configurations: List Configuration
  , responseHandler: Maybe (Message -> Setup.Command)
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
  , responseHandler = Nothing
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
    ReceivedMessage message ->
      if Message.is "_configure" "response" message then
        handleConfigResponse actions configModel message
      else
        ( configure configModel, Cmd.none )
    Continue ->
      case configModel.configurations of
        [] ->
          Exercise.init actions configModel.scenario configModel.subject
        configuration :: remaining ->
          -- Instead of Configuration these should be Setup.Command so we can better fit
          -- with the response handler function ...
          case configuration of
            ConfigCommand message ->
              ( configure { configModel | configurations = remaining, responseHandler = Nothing }
              , State.send actions <| Message.configCommandMessage message
              )
            ConfigRequest message handler ->
              ( configure { configModel | configurations = remaining, responseHandler = Just handler }
              , State.send actions <| Message.configRequestMessage message
              )
    Abort report ->
      abortWith actions configModel report
    _ ->
      Report.note "Unknown configure state!"
        |> abortWith actions configModel


handleConfigResponse : Actions msg programMsg -> Model model programMsg -> Message -> ( State.Model msg programMsg, Cmd msg )
handleConfigResponse actions configModel message =
  case Message.decode Message.decoder message of
    Ok responseMessage ->
      if Message.is "_scenario" "abort" responseMessage then
        Message.decode Report.decoder responseMessage
          |> Result.withDefault (Report.note "Unable to parse abort scenario event!")
          |> abortWith actions configModel
      else
        case configModel.responseHandler of
          Just handler ->
            case handler responseMessage of
              Setup.SendMessage nextMessage ->
                ( configure { configModel | responseHandler = Nothing }
                , State.send actions <| Message.configCommandMessage nextMessage
                )
          Nothing ->
            ( configure configModel, Cmd.none )
    Err _ ->
      ( configure configModel, Cmd.none )


abortWith : Actions msg programMsg -> Model model programMsg -> Report -> (State.Model msg programMsg, Cmd msg)
abortWith actions configModel report =
  Error.init actions
    [ configModel.scenario.specification
    , configModel.scenario.description
    ]
    "Unable to configure scenario"
    report
