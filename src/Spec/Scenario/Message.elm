module Spec.Scenario.Message exposing
  ( isScenarioMessage
  , startScenario
  , startObservation
  , abortScenario
  )

import Spec.Message as Message exposing (Message)
import Spec.Message.Internal as Message
import Json.Encode as Encode


isScenarioMessage : Message -> Bool
isScenarioMessage =
  Message.belongsTo "_scenario"


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
  Message.for "_scenario" "state"
    |> Message.withBody (Encode.string specState)
