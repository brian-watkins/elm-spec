module Spec.Scenario.State.Exercise exposing
  ( Model
  , init
  , update
  , view
  , subscriptions
  )

import Spec.Scenario.Internal as Internal exposing (Scenario, Step)
import Spec.Setup.Internal as Internal exposing (Subject)
import Spec.Scenario.State as State exposing (Msg(..), Command)
import Spec.Message exposing (Message)
import Spec.Scenario.Message as Message
import Spec.Step as Step
import Spec.Step.Command as StepCommand
import Spec.Observation.Message as Message
import Spec.Report as Report
import Spec.Claim as Claim
import Html exposing (Html)
import Browser exposing (Document)


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


update : (Message -> Cmd msg) -> Msg msg -> Model model msg -> ( Model model msg, Command (Msg msg) )
update outlet msg model =
  case msg of
    ReceivedMessage message ->
      ( { model | effects = message :: model.effects }
      , State.Send Message.stepComplete
      )

    ProgramMsg programMsg ->
      model.subject.update outlet programMsg model.programModel
        |> Tuple.mapFirst (\updated -> { model | programModel = updated })
        |> Tuple.mapSecond (\nextCommand ->
          if nextCommand == Cmd.none then
            State.Send Message.stepComplete
          else
            Cmd.map ProgramMsg nextCommand
              |> State.DoAndRender
        )

    Continue ->
      case model.steps of
        [] ->
          ( model, State.Transition )
        step :: remaining ->
          let
            updated = 
              { model
              | steps = remaining
              , conditionsApplied =
                  addIfUnique model.conditionsApplied step.condition
              }
          in
            case step.run { model = model.programModel, effects = model.effects } of
              StepCommand.SendMessage message ->
                ( updated, State.Send message )
              StepCommand.SendCommand cmd ->
                ( updated
                , Cmd.map ProgramMsg cmd
                    |> State.DoAndRender
                )
              StepCommand.DoNothing ->
                update outlet Continue updated

    Abort report ->
      ( model
      , State.SendMany
        [ Claim.Reject report
          |> Message.observation model.conditionsApplied "A spec step failed"
        , Message.abortScenario
        ]
      )

    OnUrlChange url ->
      case model.subject.onUrlChange of
        Just handler ->
          update outlet (ProgramMsg <| handler url) model
        Nothing ->
          ( model
          , State.updateWith <| Abort <| Report.batch
              [ Report.note "A URL change occurred, but no handler has been provided."
              , Report.note "Use Spec.Setup.onUrlChange to set a handler."
              ]
          )

    OnUrlRequest request ->
      case model.subject.onUrlRequest of
        Just handler ->
          update outlet (ProgramMsg <| handler request) model
        Nothing ->
          ( model
          , State.updateWith <| Abort <| Report.batch
              [ Report.note "A URL request occurred, but no handler has been provided."
              , Report.note "Use Spec.Setup.onUrlRequest to set a handler."
              ]
          )


subscriptions : Model model msg -> Sub msg
subscriptions model =
  model.subject.subscriptions model.programModel


addIfUnique : List a -> a -> List a
addIfUnique list val =
  if List.member val list then
    list
  else
    list ++ [ val ]
