module Spec.Scenario.State.Finished exposing
  ( Model
  , init
  , update
  , view
  , subscriptions
  )

import Spec.Setup.Internal as Internal exposing (Subject)
import Spec.Scenario.State as State exposing (Msg(..), Command)
import Spec.Message as Message exposing (Message)
import Spec.Markup.Message as Message
import Spec.Scenario.State.NavigationHelpers exposing (..)
import Browser exposing (Document)
import Json.Decode as Json


type alias Model model msg =
  { subject: Subject model msg
  , programModel: model
  }


init : Subject model msg -> model -> Model model msg
init subject programModel =
  { subject = subject
  , programModel = programModel
  }


view : Model model msg -> Document msg
view model =
  case model.subject.view of
    Internal.Element elementView ->
      { title = ""
      , body = [ elementView model.programModel ]
      }
    Internal.Document documentView ->
      documentView model.programModel


update : (Message -> Cmd msg) -> Msg msg -> Model model msg -> ( Model model msg, Command (Msg msg) )
update outlet msg model =
  case msg of
    ReceivedMessage message ->
      if Message.is "_navigation" "assign" message then
        handleLocationAssigned model message
      else
        ( model
        , State.Do Cmd.none
        )

    ProgramMsg programMsg ->
      model.subject.update outlet programMsg model.programModel
        |> Tuple.mapFirst (\updated -> { model | programModel = updated })
        |> Tuple.mapSecond (\nextCommand ->
          if nextCommand == Cmd.none then
            State.Send Message.runToNextAnimationFrame
          else
            Cmd.map ProgramMsg nextCommand
              |> State.DoAndRender
        )

    Continue ->
      ( model, State.Do Cmd.none )

    Abort report ->
      ( model, State.Do Cmd.none )

    OnUrlChange url ->
      case model.subject.navigationConfig of
        Just config ->
          update outlet (ProgramMsg <| config.onUrlChange url) model
        Nothing ->
          ( model
          , State.Do Cmd.none
          )

    OnUrlRequest request ->
      case model.subject.navigationConfig of
        Just config ->
          update outlet (ProgramMsg <| config.onUrlRequest request) model
        Nothing ->
          handleUrlRequest model request


subscriptions : Model model msg -> Sub msg
subscriptions model =
  model.subject.subscriptions model.programModel


handleLocationAssigned : Model model msg -> Message -> ( Model model msg, Command (Msg msg) )
handleLocationAssigned model message =
  case Message.decode Json.string message of
    Ok location ->
      case model.subject.navigationConfig of
        Just _ ->
          ( model
          , State.Do Cmd.none
          )
        Nothing ->
          ( { model | subject = navigatedSubject location model.subject }
          , State.DoAndRender Cmd.none
          )
    Err _ ->
      ( model
      , State.Do Cmd.none
      )