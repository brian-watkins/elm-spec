module Spec.Scenario.State.Configure exposing
  ( Model
  , init
  )

import Spec.Scenario.Internal exposing (Scenario)
import Spec.Setup.Internal exposing (Subject)
import Spec.Scenario.State as State exposing (Msg(..), Command)
import Spec.Scenario.Message as Message
import Spec.Message exposing (Message)


type alias Model model msg =
  { scenario: Scenario model msg
  , subject: Subject model msg
  }


init : Scenario model msg -> Subject model msg -> ( Model model msg, Command msg )
init scenario subject =
  ( { scenario = scenario
    , subject = subject
    }
  , configureWith subject.configureEnvironment
  )


configureWith : List Message -> Command msg
configureWith configMessages =
  if List.isEmpty configMessages then
    State.Send Message.configureComplete
  else
    State.SendMany <| List.map Message.configMessage configMessages