module Spec.Navigator.Internal exposing
  ( NavigationAssignment
  , navigationAssignmentDecoder
  , navigatedSubject
  , handleUrlRequest
  )

import Spec.Setup.Internal exposing (Subject, ProgramView(..))
import Json.Decode as Json
import Html
import Browser exposing (UrlRequest(..))
import Browser.Navigation
import Url



type alias NavigationAssignment =
  { href: String
  }


navigationAssignmentDecoder : Json.Decoder NavigationAssignment
navigationAssignmentDecoder =
  Json.map NavigationAssignment Json.string


navigatedSubject : String -> Subject model msg -> Subject model msg
navigatedSubject url subject =
  { subject | view = navigatedView url, update = navigatedUpdate }


navigatedView : String -> ProgramView model msg
navigatedView location =
  Element <| \_ ->
    Html.text <| "[Navigated to a page outside the control of the Elm program: " ++ location ++ "]"


navigatedUpdate : msg -> model -> (model, Cmd msg)
navigatedUpdate =
  \_ model ->
    ( model, Cmd.none )


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
