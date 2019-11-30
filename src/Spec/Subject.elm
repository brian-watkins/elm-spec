module Spec.Subject exposing
  ( SubjectProvider
  , init, initWithModel, initForApplication
  , configure
  , withSubscriptions
  , withUpdate
  , withView, withDocument
  , withLocation
  , onUrlChange, onUrlRequest
  )

import Spec.Scenario.Internal as Internal
import Spec.Message as Message exposing (Message)
import Html exposing (Html)
import Browser exposing (Document, UrlRequest)
import Browser.Navigation exposing (Key)
import Url exposing (Url)
import Json.Encode as Encode


type alias SubjectProvider model msg
  = Internal.SubjectProvider model msg


init : (model, Cmd msg) -> SubjectProvider model msg
init ( model, initialCommand ) =
  Internal.SubjectProvider
    { location = defaultUrl
    , init = \_ _ ->
        Ok <| initializeSubject ( model, initialCommand )
    }


initWithModel : model -> SubjectProvider model msg
initWithModel model =
  init ( model, Cmd.none )


initForApplication : (Url -> Key -> (model, Cmd msg)) -> SubjectProvider model msg
initForApplication generator =
  Internal.SubjectProvider
    { location = defaultUrl
    , init = \url maybeKey ->
        case maybeKey of
          Just key ->
            generator url key
              |> Ok << initializeSubject
          Nothing ->
            Err "Subject.initForApplication requires a Browser.Navigation.Key! Make sure to use Spec.browserProgram to run specs for Browser applications!"
    }


initializeSubject : ( model, Cmd msg ) -> Internal.Subject model msg
initializeSubject ( model, initialCommand ) =
  { model = model
  , initialCommand = initialCommand
  , update = \_ _ m -> (m, Cmd.none)
  , view = Internal.Document <| \_ -> { title = "", body = [ Html.text "" ] }
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


configure : Message -> SubjectProvider model msg -> SubjectProvider model msg
configure message =
  Internal.mapSubject <| \subject ->
    { subject | configureEnvironment = message :: subject.configureEnvironment }


withUpdate : (msg -> model -> (model, Cmd msg)) -> SubjectProvider model msg -> SubjectProvider model msg
withUpdate programUpdate =
  Internal.mapSubject <| \subject ->
    { subject | update = \_ -> programUpdate }


withView : (model -> Html msg) -> SubjectProvider model msg -> SubjectProvider model msg
withView view =
  Internal.mapSubject <| \subject ->
    { subject | view = Internal.Element view }


withDocument : (model -> Document msg) -> SubjectProvider model msg -> SubjectProvider model msg
withDocument view =
  Internal.mapSubject <| \subject ->
    { subject | view = Internal.Document view }


withSubscriptions : (model -> Sub msg) -> SubjectProvider model msg -> SubjectProvider model msg
withSubscriptions programSubscriptions =
  Internal.mapSubject <| \subject ->
    { subject | subscriptions = programSubscriptions }


onUrlChange : (Url -> msg) -> SubjectProvider model msg -> SubjectProvider model msg
onUrlChange handler =
  Internal.mapSubject <| \subject ->
    { subject | onUrlChange = Just handler }


onUrlRequest : (UrlRequest -> msg) -> SubjectProvider model msg -> SubjectProvider model msg
onUrlRequest handler =
  Internal.mapSubject <| \subject ->
    { subject | onUrlRequest = Just handler }


withLocation : Url -> SubjectProvider model msg -> SubjectProvider model msg
withLocation url (Internal.SubjectProvider generator) =
  Internal.SubjectProvider { generator | location = url }
    |> configure (setLocationMessage url)


setLocationMessage : Url -> Message
setLocationMessage location =
  { home = "_html"
  , name = "set-location"
  , body = Encode.string <| Url.toString location
  }
