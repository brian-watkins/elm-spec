module Spec.Setup.Internal exposing
  ( Subject
  , Setup(..)
  , ProgramView(..)
  , NavigationConfig
  , mapSubject
  , initializeSubject
  , configurationCommand
  , configurationRequest
  , Configuration(..)
  , Command(..)
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
  , update: msg -> model -> ( model, Cmd msg )
  , view: ProgramView model msg
  , subscriptions: model -> Sub msg
  , configurations: List Configuration
  , isApplication: Bool
  , navigationConfig: Maybe (NavigationConfig msg)
  }


type Configuration
  = ConfigCommand Message
  | ConfigRequest Message (Message -> Command)


type Command
  = SendMessage Message


type alias NavigationConfig msg =
  { onUrlChange: Url -> msg
  , onUrlRequest: UrlRequest -> msg
  }


type ProgramView model msg
  = Element (model -> Html msg)
  | Document (model -> Document msg)


configurationCommand : Message -> Setup model msg -> Setup model msg
configurationCommand message =
  mapSubject <| \subject ->
    { subject | configurations = ConfigCommand message :: subject.configurations }


configurationRequest : (Message -> Command) -> Message -> Setup model msg -> Setup model msg
configurationRequest handler message =
  mapSubject <| \subject ->
    { subject | configurations = ConfigRequest message handler :: subject.configurations }


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
