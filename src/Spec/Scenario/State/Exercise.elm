module Spec.Scenario.State.Exercise exposing
  ( Model
  , init
  , update
  , view
  , document
  , subscriptions
  )

import Spec.Scenario exposing (Scenario)
import Spec.Subject as Subject exposing (Subject)
import Spec.Scenario.State as State exposing (Msg(..), Command)
import Spec.Message exposing (Message)
import Spec.Scenario.Message as Message
import Spec.Step as Step exposing (Step)
import Spec.Step.Command as StepCommand
import Spec.Observation.Message as Message
import Spec.Observation.Report as Report
import Spec.Observer as Observer
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
  , conditionsApplied = [ scenario.describing ]
  , programModel = subject.model
  , effects = []
  , steps = initialCommandStep scenario subject :: scenario.steps
  }


initialCommandStep : Scenario model msg -> Subject model msg -> Step model msg
initialCommandStep scenario subject =
  Step.build scenario.description <|
    \_ ->
      Step.sendCommand subject.initialCommand


view : Model model msg -> Html msg
view model =
  model.subject.view model.programModel


document : Model model msg -> Document msg
document model =
  model.subject.document model.programModel


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
              |> State.Do
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
                  Step.condition step
                    |> addIfUnique model.conditionsApplied
              }
          in
            case Step.run step { model = model.programModel, effects = model.effects } of
              StepCommand.SendMessage message ->
                ( updated, State.Send message )
              StepCommand.SendCommand cmd ->
                ( updated
                , Cmd.map ProgramMsg cmd
                    |> State.Do
                )
              StepCommand.DoNothing ->
                update outlet Continue updated

    Abort report ->
      ( model
      , Observer.Reject report
          |> Message.observation model.conditionsApplied "A spec step failed"
          |> State.Send
      )

    OnUrlChange url ->
      case model.subject.onUrlChange of
        Just handler ->
          ( model
          , State.updateWith <| ProgramMsg <| handler url
          )
        Nothing ->
          ( model
          , State.updateWith <| Abort <| Report.batch
              [ Report.note "A URL change occurred, but no handler has been provided."
              , Report.note "Use Spec.Subject.onUrlChange to set a handler."
              ]
          )

    OnUrlRequest request ->
      ( model, State.Do Cmd.none )


subscriptions : Model model msg -> Sub msg
subscriptions model =
  model.subject.subscriptions model.programModel


addIfUnique : List a -> a -> List a
addIfUnique list val =
  if List.member val list then
    list
  else
    list ++ [ val ]
