module Spec.Scenario.State.Exercise exposing
  ( Model
  , init
  , update
  , view
  , subscriptions
  )

import Spec.Scenario.Internal as Internal exposing (Scenario, Step)
import Spec.Setup.Internal as Internal exposing (Subject)
import Spec.Scenario.State as State exposing (Msg(..), Command, Actions)
import Spec.Message as Message exposing (Message)
import Spec.Scenario.Message as Message
import Spec.Markup.Message as Message
import Spec.Step.Context as Context
import Spec.Step.Command as Step
import Spec.Observer.Message as Message
import Spec.Report as Report
import Spec.Claim as Claim
import Spec.Scenario.State.NavigationHelpers exposing (..)
import Html exposing (Html)
import Browser exposing (Document)
import Json.Decode as Json


type alias Model model msg =
  { scenario: Scenario model msg
  , subject: Subject model msg
  , conditionsApplied: List String
  , programModel: model
  , effects: List Message
  , steps: List (Step model msg)
  }


init : Scenario model msg -> Subject model msg -> Model model msg
init scenario subject =
  { scenario = scenario
  , subject = subject
  , conditionsApplied = [ scenario.specification ]
  , programModel = subject.model
  , effects = []
  , steps = initialCommandStep scenario subject :: scenario.steps
  }


initialCommandStep : Scenario model msg -> Subject model msg -> Step model msg
initialCommandStep scenario subject =
  Internal.buildStep scenario.description <|
    \_ ->
      Step.sendCommand subject.initialCommand


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
        handleLocationAssigned model message
      else
        ( { model | effects = message :: model.effects }
        , State.Do Cmd.none
        )

    ProgramMsg programMsg ->
      model.subject.update actions.outlet programMsg model.programModel
        |> Tuple.mapFirst (\updated -> { model | programModel = updated })
        |> Tuple.mapSecond (\nextCommand ->
          if nextCommand == Cmd.none then
            State.Do Cmd.none
          else
            Cmd.map ProgramMsg nextCommand
              |> doAndRender actions
        )

    Continue ->
      case model.steps of
        [] ->
          ( model, State.Transition <| actions.send Message.startObservation )
        step :: remaining ->
          let
            updated = 
              { model
              | steps = remaining
              , conditionsApplied =
                  addIfUnique model.conditionsApplied step.condition
              }
            context =
              Context.for model.programModel
                |> Context.withEffects model.effects
          in
            case step.run context of
              Step.SendMessage message ->
                ( updated, State.send actions <| Message.stepMessage message )
              Step.SendCommand cmd ->
                ( updated
                , Cmd.map ProgramMsg cmd
                    |> doAndRender actions
                )
              Step.DoNothing ->
                update actions Continue updated

    Abort report ->
      ( model
      , State.abortWith actions model.conditionsApplied "A spec step failed" report
      )

    OnUrlChange url ->
      case model.subject.navigationConfig of
        Just config ->
          update actions (ProgramMsg <| config.onUrlChange url) model
        Nothing ->
          if model.subject.isApplication then
            ( model
            , State.updateWith actions <| Abort <| Report.batch
              [ Report.note "A URL change occurred for an application, but no handler has been provided."
              , Report.note "Use Spec.Setup.forNavigation to set a handler."
              ]
            )
          else
            ( model
            , State.Do Cmd.none
            )

    OnUrlRequest request ->
      case model.subject.navigationConfig of
        Just config ->
          update actions (ProgramMsg <| config.onUrlRequest request) model
        Nothing ->
          if model.subject.isApplication then
            ( model
            , State.updateWith actions <| Abort <| Report.batch
              [ Report.note "A URL request occurred for an application, but no handler has been provided."
              , Report.note "Use Spec.Setup.forNavigation to set a handler."
              ]
            )
          else
            handleUrlRequest model request


doAndRender : Actions msg programMsg -> Cmd (Msg programMsg) -> Command msg
doAndRender actions cmd =
  State.Do <| Cmd.batch
    [ Cmd.map actions.sendToSelf cmd
    , actions.send <| Message.stepMessage <| Message.runToNextAnimationFrame
    ]


subscriptions : Model model msg -> Sub msg
subscriptions model =
  model.subject.subscriptions model.programModel


addIfUnique : List a -> a -> List a
addIfUnique list val =
  if List.member val list then
    list
  else
    list ++ [ val ]


handleLocationAssigned : Model model programMsg -> Message -> ( Model model programMsg, Command msg )
handleLocationAssigned model message =
  case Message.decode Json.string message of
    Ok location ->
      case model.subject.navigationConfig of
        Just _ ->
          ( { model | effects = message :: model.effects }
          , State.Do Cmd.none
          )
        Nothing ->
          ( { model | effects = message :: model.effects, subject = navigatedSubject location model.subject }
          , State.Do Cmd.none
          )
    Err _ ->
      ( { model | effects = message :: model.effects }
      , State.Do Cmd.none
      )