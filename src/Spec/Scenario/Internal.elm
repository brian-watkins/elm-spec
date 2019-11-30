module Spec.Scenario.Internal exposing
  ( Scenario, Subject, SubjectProvider(..), ProgramView(..), ScenarioAction, ScenarioPlan, Observation, Step
  , mapSubject, initializeSubject
  , buildStep
  , buildObservation
  , describing
  , formatScenarioDescription
  , formatCondition
  )

import Spec.Step exposing (Context, Command)
import Spec.Message exposing (Message)
import Spec.Observer exposing (Expectation)
import Browser exposing (Document, UrlRequest)
import Browser.Navigation exposing (Key)
import Url exposing (Url)
import Html exposing (Html)


type alias Scenario model msg =
  { specification: String
  , description: String
  , subjectProvider: SubjectProvider model msg
  , steps: List (Step model msg)
  , observations: List (Observation model)
  , tags: List String
  }


type SubjectProvider model msg =
  SubjectProvider
    { location: Url
    , init: Url -> Maybe Key -> Result String (Subject model msg)
    }


type alias Subject model msg =
  { model: model
  , initialCommand: Cmd msg
  , update: (Message -> Cmd msg) -> msg -> model -> ( model, Cmd msg )
  , view: ProgramView model msg
  , subscriptions: model -> Sub msg
  , configureEnvironment: List Message
  , onUrlChange: Maybe (Url -> msg)
  , onUrlRequest: Maybe (UrlRequest -> msg)
  }


type ProgramView model msg
  = Element (model -> Html msg)
  | Document (model -> Document msg)


type alias ScenarioAction model msg =
  { subjectProvider: SubjectProvider model msg
  , steps: List (Step model msg)
  }


type alias ScenarioPlan model msg =
  { subjectProvider: SubjectProvider model msg
  , steps: List (Step model msg)
  , observations: List (Observation model)
  }


type alias Observation model =
  { description: String
  , expectation: Expectation model
  }


type alias Step model msg =
  { run: Context model -> Command msg
  , condition: String
  }


mapSubject : (Subject model msg -> Subject model msg) -> SubjectProvider model msg -> SubjectProvider model msg
mapSubject mapper (SubjectProvider provider) =
  SubjectProvider
    { location = provider.location
    , init = \url maybeKey ->
        provider.init url maybeKey
          |> Result.map mapper
    }


initializeSubject : SubjectProvider model msg -> Maybe Key -> Result String (Subject model msg)
initializeSubject (SubjectProvider provider) maybeKey =
  provider.init provider.location maybeKey


buildStep : String -> (Context model -> Command msg) -> Step model msg
buildStep description stepper =
  { run = stepper
  , condition = description
  }


buildObservation : String -> Expectation model -> Observation model
buildObservation description expectation =
  { description = formatObservationDescription description
  , expectation = expectation
  }


describing : String -> Scenario model msg -> Scenario model msg
describing description scenarioData =
  { scenarioData | specification = formatSpecDescription description }


formatSpecDescription : String -> String
formatSpecDescription description =
  description


formatScenarioDescription : String -> String
formatScenarioDescription description =
  "Scenario: " ++ description


formatCondition : String -> String
formatCondition condition =
  "When " ++ condition


formatObservationDescription : String -> String
formatObservationDescription description =
  "It " ++ description
