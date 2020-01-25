module Spec.Scenario.State.NavigationHelpers exposing
  ( navigatedSubject
  , handleUrlRequest
  )

import Spec.Setup.Internal as Internal exposing (Subject, ProgramView(..))
import Spec.Message as Message exposing (Message)
import Browser exposing (UrlRequest(..))
import Browser.Navigation
import Html
import Url


handleUrlRequest : model -> UrlRequest -> ( model, Cmd msg )
handleUrlRequest model request =
  case request of
    Internal url ->
      ( model
      , Browser.Navigation.load <| Url.toString url
      )
    External url ->
      ( model
      , Browser.Navigation.load url
      )


navigatedSubject : String -> Subject model msg -> Subject model msg
navigatedSubject url subject =
  { subject | view = navigatedView url, update = navigatedUpdate }


navigatedView : String -> ProgramView model msg
navigatedView location =
  Element <| \model ->
    Html.text <| "[Navigated to a page outside the control of the Elm program: " ++ location ++ "]"


navigatedUpdate : (Message -> Cmd msg) -> msg -> model -> (model, Cmd msg)
navigatedUpdate =
  \_ _ model ->
    ( model, Cmd.none )
