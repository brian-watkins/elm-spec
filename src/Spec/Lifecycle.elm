module Spec.Lifecycle exposing
  ( Command(..)
  , isLifecycleMessage
  , commandFrom
  , configureComplete
  , stepComplete
  , observationsComplete
  , specComplete
  )

import Spec.Message as Message exposing (Message)
import Spec.Observer as Observer exposing (Verdict(..))
import Json.Encode as Encode exposing (Value)
import Json.Decode as Json


type Command
  = Start
  | NextSpec
  | StartSteps
  | NextStep


isLifecycleMessage : Message -> Bool
isLifecycleMessage =
  Message.belongsTo "_spec"


commandFrom : Message -> Maybe Command
commandFrom message =
  if Message.is "_spec" "state" message then
    Message.decode Json.string message
      |> Maybe.andThen toCommand
  else
    Nothing


toCommand : String -> Maybe Command
toCommand specState =
  case specState of
    "START" ->
      Just Start
    "NEXT_SPEC" ->
      Just NextSpec
    "START_STEPS" ->
      Just StartSteps
    "NEXT_STEP" ->
      Just NextStep
    _ ->
      Nothing


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
