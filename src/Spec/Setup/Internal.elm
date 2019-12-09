module Spec.Setup.Internal exposing
  ( Subject
  , Setup(..)
  , ProgramView(..)
  , mapSubject
  , initializeSubject
  , configure
  )

import Spec.Message exposing (Message)
import Browser exposing (Document, UrlRequest)
import Browser.Navigation exposing (Key)
import Url exposing (Url)
import Html exposing (Html)


type Setup model msg =
  Setup
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


configure : Message -> Setup model msg -> Setup model msg
configure message =
  mapSubject <| \subject ->
    { subject | configureEnvironment = message :: subject.configureEnvironment }


mapSubject : (Subject model msg -> Subject model msg) -> Setup model msg -> Setup model msg
mapSubject mapper (Setup provider) =
  Setup
    { location = provider.location
    , init = \url maybeKey ->
        provider.init url maybeKey
          |> Result.map mapper
    }


initializeSubject : Setup model msg -> Maybe Key -> Result String (Subject model msg)
initializeSubject (Setup provider) maybeKey =
  provider.init provider.location maybeKey
