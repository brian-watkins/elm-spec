module Spec.Setup exposing
  ( Setup
  , init, initWithModel, initForApplication
  , withSubscriptions
  , withUpdate
  , withView, withDocument
  , withLocation
  , forNavigation
  )

{-| Functions for the initial setup of a scenario.

@docs Setup

# Setup the Initial State
@docs initForApplication, init, initWithModel, withLocation

# Provide Core Functions
@docs withUpdate, withView, withDocument, withSubscriptions, forNavigation

-}

import Spec.Setup.Internal as Internal
import Spec.Message as Message exposing (Message)
import Html exposing (Html)
import Browser exposing (Document, UrlRequest)
import Browser.Navigation exposing (Key)
import Url exposing (Url)
import Json.Encode as Encode


{-| Represents the initial state of the world for a scenario.
-}
type alias Setup model msg
  = Internal.Setup model msg


{-| Provide an initial program model and command. The command will be executed as
the first step in the scenario script.

You might use `init` in conjunction with the `init` function of the program whose
behavior the scenario describes. In that case you could do something like:

    Spec.given (
      Spec.Setup.init (App.init testFlags)
        |> Spec.Setup.withUpdate App.update
        |> Spec.Setup.withView App.view
    )

If you are describing the behavior of a program created with `Browser.application` then
consider using `initForApplication` instead.

-}
init : (model, Cmd msg) -> Setup model msg
init ( model, initialCommand ) =
  Internal.Setup
    { location = defaultUrl
    , init = \_ _ ->
        Ok <| initializeSubject False ( model, initialCommand )
    }


{-| Provide an initial model for the program whose behavior this scenario describes.
-}
initWithModel : model -> Setup model msg
initWithModel model =
  init ( model, Cmd.none )


{-| Use the init function for a program created with `Browser.application` to set the
initial state for the scenario. You could do something like:

    Spec.given (
      Spec.Setup.initForApplication (App.init testFlags)
        |> Spec.Setup.withDocument App.view
        |> Spec.Setup.withUpdate App.update
    )

If your scenario involves location changes, you'll want to use this function in
conjunction with `Spec.Setup.forNavigation` to provide
those extra functions that an application requires. Providing these functions
is not necessary, but if you do not provde them, your spec will fail with an error
if it is setup with `initForApplication` and it tries to make location changes.

You can also use `Spec.Setup.withLocation` to set the URL that
will be passed to the application's init function at the start of the scenario.

So, a full setup for an application might look something like this:

    Spec.given (
      Spec.Setup.initForApplication (App.init testFlags)
        |> Spec.Setup.withDocument App.view
        |> Spec.Setup.withUpdate App.update
        |> Spec.Setup.forNavigation
          { onUrlChange = App.urlDidChange
          , onUrlRequest = App.urlChangeRequested
          }
        |> Spec.Setup.withLocation (someUrlWithPath "/sports")
    )

-}
initForApplication : (Url -> Key -> (model, Cmd msg)) -> Setup model msg
initForApplication generator =
  Internal.Setup
    { location = defaultUrl
    , init = \url maybeKey ->
        case maybeKey of
          Just key ->
            generator url key
              |> Ok << initializeSubject True
          Nothing ->
            Err "Spec.Setup.initForApplication requires a Browser.Navigation.Key! Make sure to use Spec.Runner.browserProgram to run specs for Browser applications!"
    }


initializeSubject : Bool -> ( model, Cmd msg ) -> Internal.Subject model msg
initializeSubject isApplication ( model, initialCommand ) =
  { model = model
  , initialCommand = initialCommand
  , update = \_ m -> (m, Cmd.none)
  , view = Internal.Document <| \_ -> { title = "", body = [ Html.text "" ] }
  , subscriptions = \_ -> Sub.none
  , configureEnvironment = []
  , isApplication = isApplication
  , navigationConfig = Nothing
  }


defaultUrl =
  { protocol = Url.Http
  , host = "elm-spec"
  , port_ = Nothing
  , path = "/"
  , query = Nothing
  , fragment = Nothing
  }


{-| Provide the `update` function for the program whose behavior the scenario describes.
-}
withUpdate : (msg -> model -> (model, Cmd msg)) -> Setup model msg -> Setup model msg
withUpdate programUpdate =
  Internal.mapSubject <| \subject ->
    { subject | update = programUpdate }


{-| Provide the `view` function for the program whose behavior the scenario describes, where
this program is created with `Browser.sandbox` or `Browser.element`.
-}
withView : (model -> Html msg) -> Setup model msg -> Setup model msg
withView view =
  Internal.mapSubject <| \subject ->
    { subject | view = Internal.Element view }


{-| Provide the `view` function for the program whose behavior the scenario describes, where
this program is created with `Browser.document` or `Browser.application`. 
-}
withDocument : (model -> Document msg) -> Setup model msg -> Setup model msg
withDocument view =
  Internal.mapSubject <| \subject ->
    { subject | view = Internal.Document view }


{-| Provide the `subscriptions` function for the program whose behavior the scenario describes.
-}
withSubscriptions : (model -> Sub msg) -> Setup model msg -> Setup model msg
withSubscriptions programSubscriptions =
  Internal.mapSubject <| \subject ->
    { subject | subscriptions = programSubscriptions }


{-| If the scenario is describing a program created with `Browser.application`, you can use
this function to supply the program's `onUrlRequest` and `onUrlChange` functions.

Use this in conjunction with `initForApplication` to describe a scenario that involves location changes.
-}
forNavigation : { onUrlRequest: UrlRequest -> msg, onUrlChange: Url -> msg } -> Setup model msg -> Setup model msg
forNavigation config =
  Internal.mapSubject <| \subject ->
    { subject | navigationConfig = Just config }


{-| Set up the scenario to begin with a particular location.

If the program whose behavior is being described was created with `Browser.application` then
this `Url` will be provided to the `init` function. In any case, this location will serve as
the base href, and any location changes will be relative to this location.

By default, the scenario begins with the location `http://elm-spec/`
-}
withLocation : Url -> Setup model msg -> Setup model msg
withLocation url (Internal.Setup generator) =
  Internal.Setup { generator | location = url }
    |> Internal.configure (setLocationMessage url)


setLocationMessage : Url -> Message
setLocationMessage location =
  Message.for "_html" "set-location"
    |> Message.withBody (
      Encode.string <| Url.toString location
    )
