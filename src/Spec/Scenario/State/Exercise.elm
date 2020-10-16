module Spec.Scenario.State.Exercise exposing
  ( init
  )

import Spec.Scenario.Internal as Internal exposing (Scenario, Step)
import Spec.Setup.Internal as Internal exposing (Subject)
import Spec.Scenario.State as State exposing (Msg(..), Actions)
import Spec.Message as Message exposing (Message)
import Spec.Message.Internal as Message
import Spec.Scenario.Message as Message
import Spec.Markup.Message as Message
import Spec.Step.Context as Context
import Spec.Step.Command as Step
import Spec.Observer.Message as Message
import Spec.Report as Report exposing (Report)
import Spec.Claim as Claim
import Spec.Scenario.State.NavigationHelpers exposing (..)
import Spec.Scenario.State.Interactive as Interactive
import Spec.Scenario.State.Observe as Observe
import Html exposing (Html)
import Browser exposing (Document)
import Json.Decode as Json


type alias Model model msg =
  { scenario: Scenario model msg
  , subject: Subject model msg
  , conditionsApplied: List String
  , programModel: model
  , effects: List Message
  , steps: List (Step model msg)
  , abortWith: Maybe Report
  , responseHandler : Maybe (Message -> Step.Command msg)
  }


init : Actions msg programMsg -> Scenario model programMsg -> Subject model programMsg -> (State.Model msg programMsg, Cmd msg)
init actions scenario subject =
  ( exercise <| initModel scenario subject
  , State.continue actions
  )


initModel : Scenario model msg -> Subject model msg -> Model model msg
initModel scenario subject =
  { scenario = scenario
  , subject = subject
  , conditionsApplied = [ scenario.specification ]
  , programModel = subject.model
  , effects = []
  , steps = initialCommandSteps scenario subject ++ scenario.steps
  , responseHandler = Nothing
  , abortWith = Nothing
  }


initialCommandSteps : Scenario model msg -> Subject model msg -> List (Step model msg)
initialCommandSteps scenario subject =
  [ \_ -> Step.recordCondition scenario.description
  , \_ -> Step.sendToProgram subject.initialCommand
  ]
    |> List.map Internal.buildStep


view : Model model msg -> Document msg
view model =
  case model.subject.view of
    Internal.Element elementView ->
      { title = ""
      , body = [ elementView model.programModel ]
      }
    Internal.Document documentView ->
      documentView model.programModel


exercise : Model model programMsg -> State.Model msg programMsg
exercise exerciseModel =
  State.Running
    { update = update exerciseModel
    , view = Just <| view exerciseModel
    , subscriptions = Just <| subscriptions exerciseModel
    }


update : Model model programMsg -> Actions msg programMsg -> State.Msg programMsg -> ( State.Model msg programMsg, Cmd msg )
update exerciseModel actions msg =
  case msg of
    ReceivedMessage message ->
      if Message.is "_navigation" "assign" message then
        handleLocationAssigned exerciseModel message
          |> Tuple.mapSecond (\_ -> sendComplete actions)
      else if Message.is "_step" "response" message then
        handleStepResponse actions exerciseModel message
      else
        ( exercise { exerciseModel | effects = message :: exerciseModel.effects }
        , sendComplete actions
        )

    ProgramMsg programMsg ->
      let
        ( updatedExerciseModel, nextCommand ) =
          exerciseModel.subject.update programMsg exerciseModel.programModel
            |> Tuple.mapFirst (\updated -> { exerciseModel | programModel = updated })
      in
        Step.SendCommand nextCommand
          |> handleStepCommand actions updatedExerciseModel

    Continue ->
      case exerciseModel.abortWith of
        Just report ->
          ( Interactive.initModel exerciseModel.subject exerciseModel.programModel
          , State.abortWith actions exerciseModel.conditionsApplied "A spec step failed" report
          )
        Nothing ->
          case exerciseModel.steps of
            [] ->
              Observe.init actions
                exerciseModel.scenario
                exerciseModel.subject
                exerciseModel.conditionsApplied
                exerciseModel.programModel
                exerciseModel.effects
            step :: remaining ->
              Context.for exerciseModel.programModel
                |> Context.withEffects exerciseModel.effects
                |> step.run
                |> handleStepCommand actions { exerciseModel | steps = remaining }

    Abort report ->
      ( exercise { exerciseModel | abortWith = Just report }
      , sendComplete actions
      )

    OnUrlChange url ->
      case exerciseModel.subject.navigationConfig of
        Just config ->
          update exerciseModel actions (ProgramMsg <| config.onUrlChange url)
        Nothing ->
          if exerciseModel.subject.isApplication then
            ( exercise exerciseModel
            , State.updateWith actions <| Abort <| Report.batch
              [ Report.note "A URL change occurred for an application, but no handler has been provided."
              , Report.note "Use Spec.Setup.forNavigation to set a handler."
              ]
            )
          else
            ( exercise exerciseModel
            , Cmd.none
            )

    OnUrlRequest request ->
      case exerciseModel.subject.navigationConfig of
        Just config ->
          update exerciseModel actions (ProgramMsg <| config.onUrlRequest request)
        Nothing ->
          if exerciseModel.subject.isApplication then
            ( exercise exerciseModel
            , State.updateWith actions <| Abort <| Report.batch
              [ Report.note "A URL request occurred for an application, but no handler has been provided."
              , Report.note "Use Spec.Setup.forNavigation to set a handler."
              ]
            )
          else
            handleUrlRequest (exercise exerciseModel) request


sendComplete : Actions msg programMsg -> Cmd msg
sendComplete actions =
  State.send actions <| Message.stepComplete


stepRequest : Message -> Message
stepRequest message =
  Message.for "_step" "request"
    |> Message.withBody (Message.encode message)


subscriptions : Model model msg -> Sub msg
subscriptions model =
  model.subject.subscriptions model.programModel


handleLocationAssigned : Model model programMsg -> Message -> ( State.Model msg programMsg, Cmd msg )
handleLocationAssigned exerciseModel message =
  case Message.decode Json.string message of
    Ok location ->
      case exerciseModel.subject.navigationConfig of
        Just _ ->
          ( exercise { exerciseModel | effects = message :: exerciseModel.effects }
          , Cmd.none
          )
        Nothing ->
          ( exercise { exerciseModel | effects = message :: exerciseModel.effects, subject = navigatedSubject location exerciseModel.subject }
          , Cmd.none
          )
    Err _ ->
      ( exercise { exerciseModel | effects = message :: exerciseModel.effects }
      , Cmd.none
      )


handleStepResponse : Actions msg programMsg -> Model model programMsg -> Message -> ( State.Model msg programMsg, Cmd msg )
handleStepResponse actions exerciseModel message =
  case Message.decode Message.decoder message of
    Ok responseMessage ->
      if Message.is "_scenario" "abort" responseMessage then
        Message.decode Report.decoder responseMessage
          |> Result.withDefault (Report.note "Unable to parse abort scenario event!")
          |> Abort
          |> update exerciseModel actions
      else
        case exerciseModel.responseHandler of
          Just responseHandler ->
            responseHandler responseMessage
              |> handleStepCommand actions { exerciseModel | responseHandler = Nothing }
          Nothing ->
            ( exercise exerciseModel, Cmd.none )
    Err _ ->
      ( exercise exerciseModel, Cmd.none )


handleStepCommand : Actions msg programMsg -> Model model programMsg -> Step.Command programMsg -> ( State.Model msg programMsg, Cmd msg)
handleStepCommand actions exerciseModel command =
  case command of
    Step.SendMessage message ->
      ( exercise exerciseModel
      , State.send actions <| Message.stepMessage message
      )
    Step.SendRequest message responseHandler ->
      ( exercise { exerciseModel | responseHandler = Just responseHandler }
      , State.send actions <| stepRequest message
      )
    Step.SendCommand cmd ->
      ( exercise exerciseModel
      , Cmd.batch
        [ Cmd.map ProgramMsg cmd
            |> Cmd.map actions.sendToSelf
        , State.send actions Step.programCommand
        ]
      )
    Step.RecordCondition condition ->
      update { exerciseModel | conditionsApplied = exerciseModel.conditionsApplied ++ [ condition ] } actions Continue
    Step.DoNothing ->
      update exerciseModel actions Continue
