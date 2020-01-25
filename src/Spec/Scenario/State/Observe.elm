module Spec.Scenario.State.Observe exposing
  ( Model
  , init
  , view
  , update
  )

import Spec.Scenario.Internal as Internal exposing (Scenario, Observation, Expectation, Judgment(..))
import Spec.Setup.Internal as Internal exposing (Subject)
import Spec.Scenario.State as State exposing (Msg(..), Command, Actions)
import Spec.Step.Context as Context exposing (Context)
import Spec.Report as Report exposing (Report)
import Spec.Claim as Claim exposing (Verdict)
import Spec.Message as Message exposing (Message)
import Spec.Observer.Message as Message
import Spec.Scenario.State.Exercise as Exercise
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


init : Exercise.Model model msg -> Model model msg
init exerciseModel =
  { scenario = exerciseModel.scenario
  , subject = exerciseModel.subject
  , conditionsApplied = exerciseModel.conditionsApplied
  , programModel = exerciseModel.programModel
  , effects = exerciseModel.effects
  , observations = exerciseModel.scenario.observations
  , inquiryHandler = Nothing
  , currentDescription = ""
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


update : Actions msg programMsg -> Msg programMsg -> Model model programMsg -> ( Model model programMsg, Command msg )
update actions msg model =
  case msg of
    ReceivedMessage message ->
      Message.decode Message.inquiryDecoder message
        |> Result.map .message
        |> Result.map (processInquiryMessage actions model)
        |> Result.withDefault
          (abortObservation actions model <| Report.note "Unable to decode inquiry result!")

    ProgramMsg programMsg ->
      ( model, State.Do Cmd.none )
    
    Continue ->
      case model.observations of
        [] ->
          ( model, State.Transition <| actions.complete )
        observation :: remaining ->
          setDescription observation model
            |> performObservation actions observation
            |> Tuple.mapFirst (\updated ->
              { updated | observations = remaining }
            )
    
    Abort report ->
      ( model
      , State.abortWith actions
          (model.conditionsApplied ++ [ model.currentDescription ]) "Unable to complete observation" report
      )

    OnUrlChange url ->
      ( model, State.Do Cmd.none )

    OnUrlRequest request ->
      ( model, State.Do Cmd.none )


abortObservation : Actions msg programMsg -> Model model programMsg -> Report -> ( Model model programMsg, Command msg )
abortObservation actions model report =
  update actions (Abort report) model


sendVerdict : Actions msg programMsg -> Model model programMsg -> Verdict -> Command msg
sendVerdict actions model verdict =
  Message.observation model.conditionsApplied model.currentDescription verdict
    |> State.send actions


toObservationContext : Model model msg -> Context model
toObservationContext model =
  Context.for model.programModel
    |> Context.withEffects model.effects


setDescription : Observation model -> Model model programMsg -> Model model programMsg
setDescription observation model =
  { model | currentDescription = observation.description }


performObservation : Actions msg programMsg -> Observation model -> Model model programMsg -> ( Model model programMsg, Command msg )
performObservation actions observation model =
  case observation.expectation <| toObservationContext model of
    Complete verdict ->
      ( { model | inquiryHandler = Nothing }
      , sendVerdict actions model verdict 
      )
    Inquire message handler ->
      ( { model | inquiryHandler = Just handler }
      , State.send actions <| Message.inquiry message
      )


processInquiryMessage : Actions msg programMsg -> Model model programMsg -> Message -> ( Model model programMsg, Command msg )
processInquiryMessage actions model message =
  if Message.is "_scenario" "abort" message then
    Message.decode Report.decoder message
      |> Result.withDefault (Report.note "Unable to decode abort message!")
      |> abortObservation actions model
  else
    ( model
    , handleInquiry message model.inquiryHandler
        |> sendVerdict actions model
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


mapTuple : (a -> b -> (c, d)) -> (a, b) -> (c, d)
mapTuple mapper ( first, second ) =
  mapper first second
