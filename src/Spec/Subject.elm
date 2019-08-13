module Spec.Subject exposing
  ( Subject
  , init
  , initWithModel
  , configure
  , pushEffect
  , effects
  , withSubscriptions
  , withUpdate
  , update
  )

import Spec.Message exposing (Message)


type alias Subject model msg =
  { model: model
  , initialCommand: Cmd msg
  , update: (Message -> Cmd msg) -> msg -> model -> ( model, Cmd msg )
  , subscriptions: model -> Sub msg
  , configureEnvironment: List Message
  , effects: List Message
  }


init : (model, Cmd msg) -> Subject model msg
init ( model, initialCommand ) =
  { model = model
  , initialCommand = initialCommand
  , update = \_ _ m -> (m, Cmd.none)
  , subscriptions = \_ -> Sub.none
  , configureEnvironment = []
  , effects = []
  }


initWithModel : model -> Subject model msg
initWithModel model =
  init ( model, Cmd.none )


configure : Message -> Subject model msg -> Subject model msg
configure message subject =
  { subject | configureEnvironment = message :: subject.configureEnvironment }


withUpdate : (msg -> model -> (model, Cmd msg)) -> Subject model msg -> Subject model msg
withUpdate programUpdate subject =
  { subject | update = \_ -> programUpdate }


withSubscriptions : (model -> Sub msg) -> Subject model msg -> Subject model msg
withSubscriptions programSubscriptions subject =
  { subject | subscriptions = programSubscriptions }


pushEffect : Message -> Subject model msg -> Subject model msg
pushEffect effect subject =
  { subject | effects = effect :: subject.effects }


effects : Subject model msg -> List Message
effects =
  .effects


update : (Message -> Cmd msg) -> msg -> Subject model msg -> ( Subject model msg, Cmd msg )
update outlet msg subject =
  subject.update outlet msg subject.model
    |> Tuple.mapFirst (\updatedModel -> { subject | model = updatedModel })