module Spec.Lifecycle exposing
  ( Msg(..)
  , isLifecycleMessage
  , toMsg
  , configureComplete
  , stepComplete
  , observationsComplete
  , specComplete
  )

import Spec.Message as Message exposing (Message)
import Spec.Observer as Observer exposing (Verdict(..))
import Json.Encode as Encode exposing (Value)
import Json.Decode as Json


type Msg
  = Start
  | NextStep
  | NextSpec
  | StartSteps
  | SpecComplete
  | ObserveSubject
  | ObservationComplete String Verdict
  | AbortSpec String


isLifecycleMessage : Message -> Bool
isLifecycleMessage =
  Message.belongsTo "_spec"


toMsg : Message -> Msg
toMsg message =
  case message.name of
    "state" ->
      Message.decode Json.string message
        |> Maybe.map toStateMsg
        |> Maybe.withDefault (AbortSpec "Unable to parse lifecycle state event!")
    "abort" ->
      Message.decode Json.string message
        |> Maybe.withDefault "Unable to parse abort spec event!"
        |> AbortSpec
    unknown ->
      AbortSpec <| "Unknown lifecycle event: " ++ unknown


toStateMsg : String -> Msg
toStateMsg specState =
  case specState of
    "START" ->
      Start
    "NEXT_SPEC" ->
      NextSpec
    "START_STEPS" ->
      StartSteps
    "NEXT_STEP" ->
      NextStep
    unknown ->
      AbortSpec <| "Unknown lifecycle state: " ++ unknown


configureComplete : Message
configureComplete =
  specStateMessage "CONFIGURE_COMPLETE"


stepComplete : Message
stepComplete =
  specStateMessage "STEP_COMPLETE"


observationsComplete : Message
observationsComplete =
  specStateMessage "OBSERVATIONS_COMPLETE"


specComplete : Message
specComplete =
  specStateMessage "SPEC_COMPLETE"


specStateMessage : String -> Message
specStateMessage specState =
  { home = "_spec"
  , name = "state"
  , body = Encode.string specState
  }
