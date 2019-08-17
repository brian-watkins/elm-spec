module Spec.Subject exposing
  ( Subject
  , init
  , initWithModel
  , configure
  , pushEffect
  , effects
  , withSubscriptions
  , withUpdate
  , withView
  , update
  , contextForObservation
  )

import Spec.Message as Message exposing (Message)
import Spec.Observer as Observer
import Spec.Context exposing (Context)
import Html exposing (Html)


type alias Subject model msg =
  { model: model
  , initialCommand: Cmd msg
  , update: (Message -> Cmd msg) -> msg -> model -> ( model, Cmd msg )
  , view: model -> Html msg
  , subscriptions: model -> Sub msg
  , configureEnvironment: List Message
  , effects: List Message
  }


init : (model, Cmd msg) -> Subject model msg
init ( model, initialCommand ) =
  { model = model
  , initialCommand = initialCommand
  , update = \_ _ m -> (m, Cmd.none)
  , view = \_ -> Html.text ""
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


withView : (model -> Html msg) -> Subject model msg -> Subject model msg
withView view subject =
  { subject | view = view }


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


contextForObservation : String -> Subject model msg -> Context model
contextForObservation key subject =
  { model = subject.model
  , effects = subject.effects
  , inquiries =
      subject.effects
        |> List.filter (Message.is "_observer" "inquiryResult")
        |> List.filterMap (Message.decode Observer.inquiryDecoder)
        |> List.filter (\inquiry -> inquiry.key == key)
        |> List.map .message
  }
