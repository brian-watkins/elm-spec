module Spec.Scenario.State.Exercise exposing
  ( init
  )

import Spec.Scenario.Internal as Internal exposing (Scenario, Step)
import Spec.Setup.Internal as Internal exposing (Subject)
import Spec.Scenario.State as State exposing (Msg(..), Actions)
import Spec.Message as Message exposing (Message)
import Spec.Scenario.Message as Message
import Spec.Markup.Message as Message
import Spec.Step.Context as Context
import Spec.Step.Command as Step
import Spec.Observer.Message as Message
import Spec.Report as Report
import Spec.Claim as Claim
import Spec.Scenario.State.NavigationHelpers exposing (..)
import Spec.Scenario.State.Interactive as Interactive
import Spec.Scenario.State.Observe as Observe
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


init : Actions msg programMsg -> Scenario model programMsg -> Subject model programMsg -> (State.Model msg programMsg, Cmd msg)
init actions scenario subject =
  ( exercise <| initModel scenario subject
  , State.continue actions
  )


initModel : Scenario model msg -> Subject model msg -> Model model msg
initModel scenario subject =
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


exercise : Model model programMsg -> State.Model msg programMsg
exercise exerciseModel =
  State.Running
    { update = update exerciseModel
    , view = Just <| view exerciseModel
    , subscriptions = Just <| subscriptions exerciseModel
    }


update : Model model programMsg -> Actions msg programMsg -> State.Msg programMsg -> ( State.Model msg programMsg, Cmd msg )
update exerciseModel actions msg =
  case msg of
    ReceivedMessage message ->
      if Message.is "_navigation" "assign" message then
        handleLocationAssigned exerciseModel message
      else
        ( exercise { exerciseModel | effects = message :: exerciseModel.effects }
        , Cmd.none
        )

    ProgramMsg programMsg ->
      exerciseModel.subject.update actions.outlet programMsg exerciseModel.programModel
        |> Tuple.mapFirst (\updated -> exercise { exerciseModel | programModel = updated })
        |> Tuple.mapSecond (\nextCommand ->
          if nextCommand == Cmd.none then
            Cmd.none
          else
            Cmd.map ProgramMsg nextCommand
              |> doAndRender actions
        )

    Continue ->
      case exerciseModel.steps of
        [] ->
          Observe.init actions
            exerciseModel.scenario
            exerciseModel.subject
            exerciseModel.conditionsApplied
            exerciseModel.programModel
            exerciseModel.effects
        step :: remaining ->
          let
            updated = 
              { exerciseModel
              | steps = remaining
              , conditionsApplied =
                  addIfUnique exerciseModel.conditionsApplied step.condition
              }
            context =
              Context.for exerciseModel.programModel
                |> Context.withEffects exerciseModel.effects
          in
            case step.run context of
              Step.SendMessage message ->
                ( exercise updated
                , State.send actions <| Message.stepMessage message
                )
              Step.SendCommand cmd ->
                ( exercise updated
                , Cmd.map ProgramMsg cmd
                    |> doAndRender actions
                )
              Step.DoNothing ->
                update updated actions Continue

    Abort report ->
      ( Interactive.initModel exerciseModel.subject exerciseModel.programModel
      , State.abortWith actions exerciseModel.conditionsApplied "A spec step failed" report
      )

    OnUrlChange url ->
      case exerciseModel.subject.navigationConfig of
        Just config ->
          update exerciseModel actions (ProgramMsg <| config.onUrlChange url)
        Nothing ->
          if exerciseModel.subject.isApplication then
            ( exercise exerciseModel
            , State.updateWith actions <| Abort <| Report.batch
              [ Report.note "A URL change occurred for an application, but no handler has been provided."
              , Report.note "Use Spec.Setup.forNavigation to set a handler."
              ]
            )
          else
            ( exercise exerciseModel
            , Cmd.none
            )

    OnUrlRequest request ->
      case exerciseModel.subject.navigationConfig of
        Just config ->
          update exerciseModel actions (ProgramMsg <| config.onUrlRequest request)
        Nothing ->
          if exerciseModel.subject.isApplication then
            ( exercise exerciseModel
            , State.updateWith actions <| Abort <| Report.batch
              [ Report.note "A URL request occurred for an application, but no handler has been provided."
              , Report.note "Use Spec.Setup.forNavigation to set a handler."
              ]
            )
          else
            handleUrlRequest (exercise exerciseModel) request


doAndRender : Actions msg programMsg -> Cmd (Msg programMsg) -> Cmd msg
doAndRender actions cmd =
  Cmd.batch
    [ Cmd.map actions.sendToSelf cmd
    , State.send actions <| Message.stepMessage <| Message.runToNextAnimationFrame
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


handleLocationAssigned : Model model programMsg -> Message -> ( State.Model msg programMsg, Cmd msg )
handleLocationAssigned exerciseModel message =
  case Message.decode Json.string message of
    Ok location ->
      case exerciseModel.subject.navigationConfig of
        Just _ ->
          ( exercise { exerciseModel | effects = message :: exerciseModel.effects }
          , Cmd.none
          )
        Nothing ->
          ( exercise { exerciseModel | effects = message :: exerciseModel.effects, subject = navigatedSubject location exerciseModel.subject }
          , Cmd.none
          )
    Err _ ->
      ( exercise { exerciseModel | effects = message :: exerciseModel.effects }
      , Cmd.none
      )