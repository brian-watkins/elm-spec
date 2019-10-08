module Spec.Subject exposing
  ( Subject
  , SubjectGenerator
  , ProgramView(..)
  , init
  , initWithModel
  , initForApplication
  , configure
  , withSubscriptions
  , withUpdate
  , withView
  , withDocument
  , withLocation
  , onUrlChange, onUrlRequest
  , mapSubject
  , generate
  )

import Spec.Message as Message exposing (Message)
import Spec.Observer as Observer
import Html exposing (Html)
import Browser exposing (Document, UrlRequest)
import Browser.Navigation exposing (Key)
import Url exposing (Url)
import Json.Encode as Encode


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


type alias SubjectGenerator model msg =
  { location: Url
  , generator: Url -> Maybe Key -> Subject model msg
  }


init : (model, Cmd msg) -> SubjectGenerator model msg
init ( model, initialCommand ) =
  { location = defaultUrl
  , generator = \_ _ ->
      initializeSubject ( model, initialCommand )
  }


initWithModel : model -> SubjectGenerator model msg
initWithModel model =
  init ( model, Cmd.none )


initForApplication : (Url -> Key -> (model, Cmd msg)) -> SubjectGenerator model msg
initForApplication generator =
  { location = defaultUrl
  , generator = \url maybeKey ->
      case maybeKey of
        Just key ->
          generator url key
            |> initializeSubject
        Nothing ->
          Debug.todo "Tried to init with key but there was no key! Make sure to use Spec.browserProgram to run your specs!"
  }


initializeSubject : ( model, Cmd msg ) -> Subject model msg
initializeSubject ( model, initialCommand ) =
  { model = model
  , initialCommand = initialCommand
  , update = \_ _ m -> (m, Cmd.none)
  , view = Document <| \_ -> { title = "", body = [ Html.text "" ] }
  , subscriptions = \_ -> Sub.none
  , configureEnvironment = []
  , onUrlChange = Nothing
  , onUrlRequest = Nothing
  }


defaultUrl =
  { protocol = Url.Http
  , host = "elm-spec"
  , port_ = Nothing
  , path = "/"
  , query = Nothing
  , fragment = Nothing
  }


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


onUrlRequest : (UrlRequest -> msg) -> SubjectGenerator model msg -> SubjectGenerator model msg
onUrlRequest handler =
  mapSubject <| \subject ->
    { subject | onUrlRequest = Just handler }


withLocation : Url -> SubjectGenerator model msg -> SubjectGenerator model msg
withLocation url generator =
  { generator | location = url }
    |> configure (setLocationMessage url)


setLocationMessage : Url -> Message
setLocationMessage location =
  { home = "_html"
  , name = "set-location"
  , body = Encode.string <| Url.toString location
  }


mapSubject : (Subject model msg -> Subject model msg) -> SubjectGenerator model msg -> SubjectGenerator model msg
mapSubject mapper generator =
  { location = generator.location
  , generator = \url maybeKey ->
      generator.generator url maybeKey
        |> mapper
  }


generate : SubjectGenerator model msg -> Maybe Key -> Subject model msg
generate generator maybeKey =
  generator.generator generator.location maybeKey