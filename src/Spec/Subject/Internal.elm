module Spec.Subject.Internal exposing
  ( Subject
  , SubjectProvider(..)
  , ProgramView(..)
  , mapSubject
  , initializeSubject
  )

import Spec.Message exposing (Message)
import Browser exposing (Document, UrlRequest)
import Browser.Navigation exposing (Key)
import Url exposing (Url)
import Html exposing (Html)


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
