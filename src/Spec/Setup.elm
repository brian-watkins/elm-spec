module Spec.Setup exposing
  ( Setup
  , init, initWithModel, initForApplication
  , configure
  , withSubscriptions
  , withUpdate
  , withView, withDocument
  , withLocation
  , onUrlChange, onUrlRequest
  )

import Spec.Setup.Internal as Internal
import Spec.Message as Message exposing (Message)
import Html exposing (Html)
import Browser exposing (Document, UrlRequest)
import Browser.Navigation exposing (Key)
import Url exposing (Url)
import Json.Encode as Encode


type alias Setup model msg
  = Internal.Setup model msg


init : (model, Cmd msg) -> Setup model msg
init ( model, initialCommand ) =
  Internal.Setup
    { location = defaultUrl
    , init = \_ _ ->
        Ok <| initializeSubject ( model, initialCommand )
    }


initWithModel : model -> Setup model msg
initWithModel model =
  init ( model, Cmd.none )


initForApplication : (Url -> Key -> (model, Cmd msg)) -> Setup model msg
initForApplication generator =
  Internal.Setup
    { location = defaultUrl
    , init = \url maybeKey ->
        case maybeKey of
          Just key ->
            generator url key
              |> Ok << initializeSubject
          Nothing ->
            Err "Spec.Setup.initForApplication requires a Browser.Navigation.Key! Make sure to use Spec.Runner.browserProgram to run specs for Browser applications!"
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


configure : Message -> Setup model msg -> Setup model msg
configure message =
  Internal.mapSubject <| \subject ->
    { subject | configureEnvironment = message :: subject.configureEnvironment }


withUpdate : (msg -> model -> (model, Cmd msg)) -> Setup model msg -> Setup model msg
withUpdate programUpdate =
  Internal.mapSubject <| \subject ->
    { subject | update = \_ -> programUpdate }


withView : (model -> Html msg) -> Setup model msg -> Setup model msg
withView view =
  Internal.mapSubject <| \subject ->
    { subject | view = Internal.Element view }


withDocument : (model -> Document msg) -> Setup model msg -> Setup model msg
withDocument view =
  Internal.mapSubject <| \subject ->
    { subject | view = Internal.Document view }


withSubscriptions : (model -> Sub msg) -> Setup model msg -> Setup model msg
withSubscriptions programSubscriptions =
  Internal.mapSubject <| \subject ->
    { subject | subscriptions = programSubscriptions }


onUrlChange : (Url -> msg) -> Setup model msg -> Setup model msg
onUrlChange handler =
  Internal.mapSubject <| \subject ->
    { subject | onUrlChange = Just handler }


onUrlRequest : (UrlRequest -> msg) -> Setup model msg -> Setup model msg
onUrlRequest handler =
  Internal.mapSubject <| \subject ->
    { subject | onUrlRequest = Just handler }


withLocation : Url -> Setup model msg -> Setup model msg
withLocation url (Internal.Setup generator) =
  Internal.Setup { generator | location = url }
    |> configure (setLocationMessage url)


setLocationMessage : Url -> Message
setLocationMessage location =
  Message.for "_html" "set-location"
    |> Message.withBody (
      Encode.string <| Url.toString location
    )
