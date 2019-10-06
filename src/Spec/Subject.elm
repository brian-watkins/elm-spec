module Spec.Subject exposing
  ( Subject
  , SubjectGenerator
  , ProgramView(..)
  , init
  , initWithModel
  , initWithKey
  , configure
  , withSubscriptions
  , withUpdate
  , withView
  , withDocument
  , onUrlChange
  , mapSubject
  )

import Spec.Message as Message exposing (Message)
import Spec.Observer as Observer
import Html exposing (Html)
import Browser exposing (Document)
import Browser.Navigation exposing (Key)
import Url exposing (Url)


type alias Subject model msg =
  { model: model
  , initialCommand: Cmd msg
  , update: (Message -> Cmd msg) -> msg -> model -> ( model, Cmd msg )
  , view: ProgramView model msg
  , subscriptions: model -> Sub msg
  , configureEnvironment: List Message
  , onUrlChange: Maybe (Url -> msg)
  }


type ProgramView model msg
  = Element (model -> Html msg)
  | Document (model -> Document msg)


type alias SubjectGenerator model msg =
  Maybe Key -> Subject model msg


init : (model, Cmd msg) -> SubjectGenerator model msg
init ( model, initialCommand ) =
  \maybeKey ->
    { model = model
    , initialCommand = initialCommand
    , update = \_ _ m -> (m, Cmd.none)
    , view = Element <| \_ -> Html.text ""
    , subscriptions = \_ -> Sub.none
    , configureEnvironment = []
    , onUrlChange = Nothing
    }


initWithModel : model -> SubjectGenerator model msg
initWithModel model =
  init ( model, Cmd.none )


initWithKey : (Key -> (model, Cmd msg)) -> SubjectGenerator model msg
initWithKey generator =
  \maybeKey ->
    case maybeKey of
      Just key ->
        let
          ( model, initialCommand ) = generator key
        in
          { model = model
          , initialCommand = initialCommand
          , update = \_ _ m -> (m, Cmd.none)
          , view = Document <| \_ -> { title = "", body = [ Html.text "" ] }
          , subscriptions = \_ -> Sub.none
          , configureEnvironment = []
          , onUrlChange = Nothing
          }
      Nothing ->
        Debug.todo "Tried to init with key but there was no key! Make sure to use Spec.browserProgram to run your specs!"


configure : Message -> SubjectGenerator model msg -> SubjectGenerator model msg
configure message =
  mapSubject <| \subject ->
    { subject | configureEnvironment = message :: subject.configureEnvironment }


withUpdate : (msg -> model -> (model, Cmd msg)) -> SubjectGenerator model msg -> SubjectGenerator model msg
withUpdate programUpdate =
  mapSubject <| \subject ->
    { subject | update = \_ -> programUpdate }


withView : (model -> Html msg) -> SubjectGenerator model msg -> SubjectGenerator model msg
withView view =
  mapSubject <| \subject ->
    { subject | view = Element view }


withDocument : (model -> Document msg) -> SubjectGenerator model msg -> SubjectGenerator model msg
withDocument view =
  mapSubject <| \subject ->
    { subject | view = Document view }


withSubscriptions : (model -> Sub msg) -> SubjectGenerator model msg -> SubjectGenerator model msg
withSubscriptions programSubscriptions =
  mapSubject <| \subject ->
    { subject | subscriptions = programSubscriptions }


onUrlChange : (Url -> msg) -> SubjectGenerator model msg -> SubjectGenerator model msg
onUrlChange handler =
  mapSubject <| \subject ->
    { subject | onUrlChange = Just handler }


mapSubject : (Subject model msg -> Subject model msg) -> SubjectGenerator model msg -> SubjectGenerator model msg
mapSubject mapper generator =
  mapper << generator