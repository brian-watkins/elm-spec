module Spec.Scenario.Message exposing
  ( isScenarioMessage
  , configureComplete
  , stepComplete
  , observationsComplete
  )

import Spec.Message as Message exposing (Message)
import Json.Encode as Encode exposing (Value)


isScenarioMessage : Message -> Bool
isScenarioMessage =
  Message.belongsTo "_scenario"


configureComplete : Message
configureComplete =
  scenarioStateMessage "CONFIGURE_COMPLETE"


stepComplete : Message
stepComplete =
  scenarioStateMessage "STEP_COMPLETE"


observationsComplete : Message
observationsComplete =
  scenarioStateMessage "OBSERVATIONS_COMPLETE"


scenarioStateMessage : String -> Message
scenarioStateMessage specState =
  { home = "_scenario"
  , name = "state"
  , body = Encode.string specState
  }
