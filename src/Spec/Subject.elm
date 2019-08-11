module Spec.Subject exposing
  ( Subject
  , fragment
  , worker
  , configure
  , pushEffect
  , effects
  , withSubscriptions
  , update
  )

import Spec.Message exposing (Message)


type alias Subject model msg =
  { model: model
  , initialCommand: Cmd msg
  , update: msg -> model -> ( model, Cmd msg )
  , subscriptions: model -> Sub msg
  , configureEnvironment: List Message
  , effects: List Message
  }


fragment : model -> (msg -> model -> (model, Cmd msg)) -> Subject model msg
fragment model =
  worker (\_ -> (model, Cmd.none))


worker : (() -> (model, Cmd msg)) -> (msg -> model -> (model, Cmd msg)) -> Subject model msg
worker initGenerator workerUpdate =
  let
      ( model, initialCommand ) = initGenerator ()
  in
    { model = model
    , initialCommand = initialCommand
    , update = workerUpdate
    , subscriptions = \_ -> Sub.none
    , configureEnvironment = []
    , effects = []
    }


configure : Message -> Subject model msg -> Subject model msg
configure message subject =
  { subject | configureEnvironment = message :: subject.configureEnvironment }


withSubscriptions : (model -> Sub msg) -> Subject model msg -> Subject model msg
withSubscriptions programSubscriptions subject =
  { subject | subscriptions = programSubscriptions }


pushEffect : Message -> Subject model msg -> Subject model msg
pushEffect effect subject =
  { subject | effects = effect :: subject.effects }


effects : Subject model msg -> List Message
effects =
  .effects


update : msg -> Subject model msg -> ( Subject model msg, Cmd msg )
update msg subject =
  subject.update msg subject.model
    |> Tuple.mapFirst (\updatedModel -> { subject | model = updatedModel })