module Spec.Scenario.State.Interactive exposing
  ( initModel
  )

import Spec.Setup.Internal as Internal exposing (Subject)
import Spec.Scenario.State as State exposing (Msg(..), Actions)
import Spec.Message as Message exposing (Message)
import Spec.Scenario.Message as Message
import Spec.Scenario.State.NavigationHelpers exposing (..)
import Browser exposing (Document)
import Json.Decode as Json


type alias Model model msg =
  { subject: Subject model msg
  , programModel: model
  }


initModel : Subject model programMsg -> model -> State.Model msg programMsg
initModel subject programModel =
  interactive
    { subject = subject
    , programModel = programModel
    }


interactive : Model model programMsg -> State.Model msg programMsg
interactive interactiveModel =
  State.Running
    { update = update interactiveModel
    , view = Just <| view interactiveModel
    , subscriptions = Just <| subscriptions interactiveModel
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


update : Model model programMsg -> Actions msg programMsg -> State.Msg programMsg -> ( State.Model msg programMsg, Cmd msg )
update interactiveModel actions msg =
  case msg of
    ReceivedMessage message ->
      if Message.is "_navigation" "assign" message then
        handleLocationAssigned actions interactiveModel message
      else
        ( interactive interactiveModel, Cmd.none )

    ProgramMsg programMsg ->
      interactiveModel.subject.update programMsg interactiveModel.programModel
        |> Tuple.mapFirst (\updated -> interactive { interactiveModel | programModel = updated })
        |> Tuple.mapSecond (\nextCommand ->
          if nextCommand == Cmd.none then
            State.send actions Message.runToNextAnimationFrame
          else
            Cmd.map ProgramMsg nextCommand
              |> doAndRender actions
        )

    Continue ->
      ( interactive interactiveModel, actions.complete )

    Abort report ->
      ( interactive interactiveModel, Cmd.none )

    OnUrlChange url ->
      case interactiveModel.subject.navigationConfig of
        Just config ->
          update interactiveModel actions (ProgramMsg <| config.onUrlChange url)
        Nothing ->
          ( interactive interactiveModel, Cmd.none )

    OnUrlRequest request ->
      case interactiveModel.subject.navigationConfig of
        Just config ->
          update interactiveModel actions (ProgramMsg <| config.onUrlRequest request)
        Nothing ->
          handleUrlRequest (interactive interactiveModel) request


doAndRender : Actions msg programMsg -> Cmd (Msg programMsg) -> Cmd msg
doAndRender actions cmd =
  Cmd.batch
    [ Cmd.map actions.sendToSelf cmd
    , State.send actions <| Message.runToNextAnimationFrame
    ]


subscriptions : Model model msg -> Sub msg
subscriptions model =
  model.subject.subscriptions model.programModel


handleLocationAssigned : Actions msg programMsg -> Model model programMsg -> Message -> ( State.Model msg programMsg, Cmd msg )
handleLocationAssigned actions interactiveModel message =
  case Message.decode Json.string message of
    Ok location ->
      case interactiveModel.subject.navigationConfig of
        Just _ ->
          ( interactive interactiveModel, Cmd.none )
        Nothing ->
          ( interactive { interactiveModel | subject = navigatedSubject location interactiveModel.subject }
          , doAndRender actions Cmd.none
          )
    Err _ ->
      ( interactive interactiveModel, Cmd.none )