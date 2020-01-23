module Spec.Scenario.State.Finished exposing
  ( Model
  , init
  , update
  , view
  , subscriptions
  )

import Spec.Setup.Internal as Internal exposing (Subject)
import Spec.Scenario.State as State exposing (Msg(..), Command, Actions)
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


update : Actions msg programMsg -> Msg programMsg -> Model model programMsg -> ( Model model programMsg, Command msg )
update actions msg model =
  case msg of
    ReceivedMessage message ->
      if Message.is "_navigation" "assign" message then
        handleLocationAssigned actions model message
      else
        ( model
        , State.Do Cmd.none
        )

    ProgramMsg programMsg ->
      model.subject.update actions.outlet programMsg model.programModel
        |> Tuple.mapFirst (\updated -> { model | programModel = updated })
        |> Tuple.mapSecond (\nextCommand ->
          if nextCommand == Cmd.none then
            State.send actions Message.runToNextAnimationFrame
          else
            Cmd.map ProgramMsg nextCommand
              |> doAndRender actions
        )

    Continue ->
      ( model, State.Do actions.complete )

    Abort report ->
      ( model, State.Do Cmd.none )

    OnUrlChange url ->
      case model.subject.navigationConfig of
        Just config ->
          update actions (ProgramMsg <| config.onUrlChange url) model
        Nothing ->
          ( model
          , State.Do Cmd.none
          )

    OnUrlRequest request ->
      case model.subject.navigationConfig of
        Just config ->
          update actions (ProgramMsg <| config.onUrlRequest request) model
        Nothing ->
          handleUrlRequest model request


doAndRender : Actions msg programMsg -> Cmd (Msg programMsg) -> Command msg
doAndRender actions cmd =
  State.Do <| Cmd.batch
    [ Cmd.map actions.sendToSelf cmd
    , actions.send <| Message.runToNextAnimationFrame
    ]


subscriptions : Model model msg -> Sub msg
subscriptions model =
  model.subject.subscriptions model.programModel


handleLocationAssigned : Actions msg programMsg -> Model model programMsg -> Message -> ( Model model programMsg, Command msg )
handleLocationAssigned actions model message =
  case Message.decode Json.string message of
    Ok location ->
      case model.subject.navigationConfig of
        Just _ ->
          ( model
          , State.Do Cmd.none
          )
        Nothing ->
          ( { model | subject = navigatedSubject location model.subject }
          , doAndRender actions Cmd.none
          )
    Err _ ->
      ( model
      , State.Do Cmd.none
      )