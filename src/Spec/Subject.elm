module Spec.Subject exposing
  ( Subject
  , init
  , initWithModel
  , configure
  , withSubscriptions
  , withUpdate
  , withView
  , subscriptions
  )

import Spec.Message as Message exposing (Message)
import Spec.Observer as Observer
import Html exposing (Html)


type alias Subject model msg =
  { model: model
  , initialCommand: Cmd msg
  , update: (Message -> Cmd msg) -> msg -> model -> ( model, Cmd msg )
  , view: model -> Html msg
  , subscriptions: model -> Sub msg
  , configureEnvironment: List Message
  }


init : (model, Cmd msg) -> Subject model msg
init ( model, initialCommand ) =
  { model = model
  , initialCommand = initialCommand
  , update = \_ _ m -> (m, Cmd.none)
  , view = \_ -> Html.text ""
  , subscriptions = \_ -> Sub.none
  , configureEnvironment = []
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


withView : (model -> Html msg) -> Subject model msg -> Subject model msg
withView view subject =
  { subject | view = view }


withSubscriptions : (model -> Sub msg) -> Subject model msg -> Subject model msg
withSubscriptions programSubscriptions subject =
  { subject | subscriptions = programSubscriptions }


subscriptions : Subject model msg -> Sub msg
subscriptions subject =
  subject.subscriptions subject.model