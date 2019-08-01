module Spec.Subject exposing
  ( Subject
  , fragment
  , worker
  , configure
  , pushEffect
  , effects
  , withSubscriptions
  )

import Spec.Types exposing (..)
import Spec.Message exposing (Message)


type alias Subject model msg =
  { model: model
  , initialCommand: Cmd msg
  , update: msg -> model -> ( model, Cmd msg )
  , subscriptions: model -> Sub msg
  , configureEnvironment: Cmd (Msg msg)
  , effects: List Message
  }


fragment : model -> (msg -> model -> (model, Cmd msg)) -> Subject model msg
fragment model =
  worker (\_ -> (model, Cmd.none))


worker : (() -> (model, Cmd msg)) -> (msg -> model -> (model, Cmd msg)) -> Subject model msg
worker initGenerator update =
  let
      ( model, initialCommand ) = initGenerator ()
  in
    { model = model
    , initialCommand = initialCommand
    , update = update
    , subscriptions = \_ -> Sub.none
    , configureEnvironment = Cmd.none
    , effects = []
    }


configure : Cmd (Msg msg) -> Subject model msg -> Subject model msg
configure command subject =
  { subject | configureEnvironment = Cmd.batch [ subject.configureEnvironment, command ] }


withSubscriptions : (model -> Sub msg) -> Subject model msg -> Subject model msg
withSubscriptions programSubscriptions subject =
  { subject | subscriptions = programSubscriptions }


pushEffect : Message -> Subject model msg -> Subject model msg
pushEffect effect subject =
  { subject | effects = effect :: subject.effects }


effects : Subject model msg -> List Message
effects =
  .effects
