module Spec.Scenario.Message exposing
  ( isScenarioMessage
  , startScenario
  , configureComplete
  , stepComplete
  , startObservation
  , abortScenario
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


startObservation : Message
startObservation =
  scenarioStateMessage "OBSERVATION_START"


startScenario : Message
startScenario =
  scenarioStateMessage "START"


abortScenario : Message
abortScenario =
  scenarioStateMessage "ABORT"


scenarioStateMessage : String -> Message
scenarioStateMessage specState =
  { home = "_scenario"
  , name = "state"
  , body = Encode.string specState
  }
