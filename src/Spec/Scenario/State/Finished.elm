module Spec.Scenario.State.Finished exposing
  ( Model
  , init
  , update
  , view
  , subscriptions
  )

import Spec.Subject as Subject exposing (Subject)
import Spec.Scenario.State as State exposing (Msg(..), Command)
import Spec.Message exposing (Message)
import Spec.Markup.Message as Message
import Spec.Step as Step exposing (Step)
import Spec.Step.Command as StepCommand
import Spec.Scenario.State.Observe as Observe
import Html exposing (Html)
import Browser exposing (Document)
import Json.Encode as Encode


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
    Subject.Element elementView ->
      { title = ""
      , body = [ elementView model.programModel ]
      }
    Subject.Document documentView ->
      documentView model.programModel


update : (Message -> Cmd msg) -> Msg msg -> Model model msg -> ( Model model msg, Command (Msg msg) )
update outlet msg model =
  case msg of
    ReceivedMessage message ->
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
      case model.subject.onUrlChange of
        Just handler ->
          update outlet (ProgramMsg <| handler url) model
        Nothing ->
          ( model
          , State.Do Cmd.none
          )

    OnUrlRequest request ->
      case model.subject.onUrlRequest of
        Just handler ->
          update outlet (ProgramMsg <| handler request) model
        Nothing ->
          ( model
          , State.Do Cmd.none
          )


subscriptions : Model model msg -> Sub msg
subscriptions model =
  model.subject.subscriptions model.programModel
