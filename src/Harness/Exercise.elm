module Harness.Exercise exposing
  ( Model, Msg(..)
  , Actions
  , ExposedStepsRepository
  , defaultModel
  , generateSteps
  , init
  , initForInitialCommand
  , wait
  , update
  , subscriptions
  )

import Spec.Message as Message exposing (Message)
import Harness.Types exposing (..)
import Harness.Errors as Errors
import Spec.Claim as Claim
import Spec.Step exposing (Step)
import Spec.Step.Command as Step
import Spec.Step.Message as Message
import Spec.Observer.Message as Message
import Spec.Message.Internal as Message
import Spec.Report as Report exposing (Report)
import Spec.Step.Context exposing (Context)
import Json.Decode as Json


type alias Model model programMsg =
  { stepsToRun: List (Step model programMsg)
  , responseHandler: Maybe (Message -> Step.Command programMsg)
  }


defaultModel : Model model programMsg
defaultModel =
  { stepsToRun = []
  , responseHandler = Nothing
  }


type Msg programMsg
  = Continue
  | ReceivedMessage Message
  | Error Report


type alias Actions msg programMsg =
  { send: Message -> Cmd msg
  , sendProgramCommand: Cmd programMsg -> Cmd msg
  , storeEffect: Message -> Cmd msg
  , sendToSelf: (Msg programMsg) -> Cmd msg
  , finished: Cmd msg
  , listen: (Message -> Msg programMsg) -> Sub msg
  }


type alias ExposedStepsRepository model msg =
  { get: String -> Maybe (HarnessFunction (List (Step model msg)))
  }


generateSteps : ExposedStepsRepository model programMsg -> Message -> Result Report (List (Step model programMsg))
generateSteps steps message =
  Result.map2 Tuple.pair
    (Message.decode (Json.field "steps" Json.string) message)
    (Message.decode (Json.field "config" Json.value) message)
    |> Result.mapError Report.note
    |> Result.andThen (\(stepName, config) ->
      case steps.get stepName of
        Just stepGenerator ->
          stepGenerator config
            |> Result.mapError (Errors.configurationError "script" stepName)
        Nothing ->
          Err <| Errors.notFoundError "script" stepName
    )


init : Actions msg programMsg -> List (Step model programMsg) -> ( Model model programMsg, Cmd msg )
init actions steps =
  ( { defaultModel | stepsToRun = steps }
  , actions.sendToSelf Continue
  )


initForInitialCommand : Actions msg programMsg -> Cmd programMsg -> ( Model model programMsg, Cmd msg )
initForInitialCommand actions command =
  ( { defaultModel | stepsToRun = [ \_ -> Step.sendToProgram command ] }
  , actions.sendToSelf Continue
  )


wait : Actions msg programMsg -> ( Model model programMsg, Cmd msg )
wait actions =
  ( defaultModel
  , actions.send Message.stepComplete
  )


update : Actions msg programMsg -> Context model -> Msg programMsg -> Model model programMsg -> ( Model model programMsg, Cmd msg )
update actions context msg model =
  case msg of
    ReceivedMessage message ->
      if Message.is "_step" "response" message then
        handleStepResponse actions model message
      else
        ( model
        , Cmd.batch
          [ actions.storeEffect message
          , actions.send Message.stepComplete
          ]
        )
    Continue ->
      case model.stepsToRun of
        [] -> 
          ( model, actions.finished )
        step :: remaining ->
          step context
            |> handleStepCommand actions { model | stepsToRun = remaining }
    Error report ->
      ( { model | stepsToRun = [] }
      , actions.send <| Message.observation [] "A Spec step failed" <| Claim.Reject report
      )


handleStepCommand : Actions msg programMsg -> Model model programMsg -> Step.Command programMsg -> ( Model model programMsg, Cmd msg)
handleStepCommand actions model command =
  case command of
    Step.Batch commands ->
      ( { model | stepsToRun = List.append (List.map makeStep commands) model.stepsToRun }
      , actions.send Message.stepComplete
      )
    Step.SendMessage message ->
      ( model
      , actions.send <| Message.stepMessage message
      )
    Step.SendCommand cmd ->
      ( model
      , actions.sendProgramCommand cmd
      )
    Step.SendRequest message responseHandler ->
      ( { model | responseHandler = Just responseHandler }
      , actions.send <| Message.stepRequest message
      )
    Step.RecordCondition _ ->
      ( model, Cmd.none )
    Step.RecordEffect effect ->
      ( model
      , Cmd.batch
        [ actions.storeEffect effect
        , actions.send Message.stepComplete
        ]
      )
    Step.Halt report ->
      ( model
      , actions.sendToSelf <| Error report
      )


makeStep : Step.Command programMsg -> Step model programMsg
makeStep command =
  \_ -> command


handleStepResponse : Actions msg programMsg -> Model model programMsg -> Message -> ( Model model programMsg, Cmd msg )
handleStepResponse actions model message =
  case Message.decode Message.decoder message of
    Ok responseMessage ->
      if Message.is "_scenario" "abort" responseMessage then
        ( model
        , Message.decode Report.decoder responseMessage
            |> Result.withDefault (Report.note "Unable to parse abort scenario event!")
            |> Error
            |> actions.sendToSelf
        )
      else
        case model.responseHandler of
          Just responseHandler ->
            responseHandler responseMessage
              |> handleStepCommand actions { model | responseHandler = Nothing }
          Nothing ->
            ( model, Cmd.none )
    Err _ ->
      ( model, Cmd.none )


subscriptions : Actions msg programMsg -> Model model programMsg -> Sub msg
subscriptions actions _ =
  actions.listen (\message ->
    if Message.is "_scenario" "state" message then
      case Message.decode Json.string message |> Result.withDefault "" of
        "CONTINUE" ->
          Continue
        _ ->
          ReceivedMessage message
    else if Message.is "_scenario" "abort" message then
      case Message.decode Report.decoder message of
        Ok report ->
          Error report
        Err error ->
          Error <| Report.fact "Could not decode a Step abort message" error
    else
      ReceivedMessage message
  )
