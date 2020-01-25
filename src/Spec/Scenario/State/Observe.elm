module Spec.Scenario.State.Observe exposing
  ( init
  )

import Spec.Scenario.Internal as Internal exposing (Scenario, Observation, Expectation, Judgment(..))
import Spec.Setup.Internal as Internal exposing (Subject)
import Spec.Scenario.State as State exposing (Msg(..), Actions)
import Spec.Step.Context as Context exposing (Context)
import Spec.Report as Report exposing (Report)
import Spec.Claim as Claim exposing (Verdict)
import Spec.Message as Message exposing (Message)
import Spec.Scenario.Message as Message
import Spec.Observer.Message as Message
import Spec.Scenario.State.Interactive as Interactive
import Html exposing (Html)
import Browser exposing (Document)


type alias Model model msg =
  { scenario: Scenario model msg
  , subject: Subject model msg
  , conditionsApplied: List String
  , programModel: model
  , effects: List Message
  , observations: List (Observation model)
  , inquiryHandler: Maybe (Message -> Judgment model)
  , currentDescription: String
  }


init : Actions msg programMsg -> Scenario model programMsg -> Subject model programMsg -> List String -> model -> List Message -> (State.Model msg programMsg, Cmd msg)
init actions scenario subject conditionsApplied programModel effects =
  ( observe <| initModel scenario subject conditionsApplied programModel effects
  , State.send actions Message.startObservation
  )


initModel : Scenario model msg -> Subject model msg -> List String -> model -> List Message -> Model model msg
initModel scenario subject conditionsApplied programModel effects =
  { scenario = scenario
  , subject = subject
  , conditionsApplied = conditionsApplied
  , programModel = programModel
  , effects = effects
  , observations = scenario.observations
  , inquiryHandler = Nothing
  , currentDescription = ""
  }


observe : Model model programMsg -> State.Model msg programMsg
observe observeModel =
  State.Running
    { update = update observeModel
    , view = Just <| view observeModel
    , subscriptions = Nothing
    }


view : Model model msg -> Document msg
view model =
  case model.subject.view of
    Internal.Element elementView ->
      { title = ""
      , body = [ elementView model.programModel ]
      }
    Internal.Document documentView ->
      documentView model.programModel


update : Model model programMsg -> Actions msg programMsg -> State.Msg programMsg -> ( State.Model msg programMsg, Cmd msg )
update observeModel actions msg =
  case msg of
    ReceivedMessage message ->
      Message.decode Message.inquiryDecoder message
        |> Result.map .message
        |> Result.map (processInquiryMessage actions observeModel)
        |> Result.withDefault
          (abortObservation actions observeModel <| Report.note "Unable to decode inquiry result!")

    ProgramMsg programMsg ->
      ( observe observeModel, Cmd.none )
    
    Continue ->
      case observeModel.observations of
        [] ->
          ( Interactive.initModel observeModel.subject observeModel.programModel
          , actions.complete
          )
        observation :: remaining ->
          setDescription observation observeModel
            |> performObservation actions observation
            |> Tuple.mapFirst (\updated ->
              observe { updated | observations = remaining }
            )
    
    Abort report ->
      ( Interactive.initModel observeModel.subject observeModel.programModel
      , State.abortWith actions
          (observeModel.conditionsApplied ++ [ observeModel.currentDescription ])
          "Unable to complete observation" report
      )

    OnUrlChange url ->
      ( observe observeModel, Cmd.none )

    OnUrlRequest request ->
      ( observe observeModel, Cmd.none )


abortObservation : Actions msg programMsg -> Model model programMsg -> Report -> ( State.Model msg programMsg, Cmd msg )
abortObservation actions observeModel report =
  update observeModel actions (Abort report)


sendVerdict : Actions msg programMsg -> Model model programMsg -> Verdict -> Cmd msg
sendVerdict actions observeModel verdict =
  Message.observation observeModel.conditionsApplied observeModel.currentDescription verdict
    |> State.send actions


toObservationContext : Model model msg -> Context model
toObservationContext model =
  Context.for model.programModel
    |> Context.withEffects model.effects


setDescription : Observation model -> Model model programMsg -> Model model programMsg
setDescription observation model =
  { model | currentDescription = observation.description }


performObservation : Actions msg programMsg -> Observation model -> Model model programMsg -> ( Model model programMsg, Cmd msg )
performObservation actions observation observeModel =
  case observation.expectation <| toObservationContext observeModel of
    Complete verdict ->
      ( { observeModel | inquiryHandler = Nothing }
      , sendVerdict actions observeModel verdict 
      )
    Inquire message handler ->
      ( { observeModel | inquiryHandler = Just handler }
      , State.send actions <| Message.inquiry message
      )


processInquiryMessage : Actions msg programMsg -> Model model programMsg -> Message -> ( State.Model msg programMsg, Cmd msg )
processInquiryMessage actions observeModel message =
  if Message.is "_scenario" "abort" message then
    Message.decode Report.decoder message
      |> Result.withDefault (Report.note "Unable to decode abort message!")
      |> abortObservation actions observeModel
  else
    ( observe observeModel
    , handleInquiry message observeModel.inquiryHandler
        |> sendVerdict actions observeModel
    )


handleInquiry : Message -> Maybe (Message -> Judgment model) -> Verdict
handleInquiry message maybeHandler =
  maybeHandler
    |> Maybe.map (inquiryResult message)
    |> Maybe.withDefault (Claim.Reject <| Report.note "No Inquiry Handler!")
    

inquiryResult : Message -> (Message -> Judgment model) -> Verdict
inquiryResult message handler =
  case handler message of
    Complete verdict ->
      verdict
    Inquire _ _ ->
      Claim.Reject <| Report.note "Recursive Inquiry not supported!"
