module Spec.Scenario.State.Exercise exposing
  ( Model
  , init
  , update
  , view
  , subscriptions
  )

import Spec.Scenario exposing (Scenario)
import Spec.Subject as Subject
import Spec.Scenario.State as State exposing (Msg(..), Command)
import Spec.Message exposing (Message)
import Spec.Scenario.Message as Message
import Spec.Step as Step exposing (Step)
import Spec.Step.Command as StepCommand
import Spec.Observation.Message as Message
import Spec.Observer as Observer
import Html exposing (Html)


type alias Model model msg =
  { scenario: Scenario model msg
  , conditionsApplied: List String
  , programModel: model
  , effects: List Message
  , steps: List (Step model msg)
  }


init : Scenario model msg -> Model model msg
init scenario =
  { scenario = scenario
  , conditionsApplied = [ scenario.describing ]
  , programModel = scenario.subject.model
  , effects = []
  , steps = scenario.steps
  }


view : Model model msg -> Html msg
view model =
  model.scenario.subject.view model.programModel


update : (Message -> Cmd msg) -> Msg msg -> Model model msg -> ( Model model msg, Command (Msg msg) )
update outlet msg model =
  case msg of
    ReceivedMessage message ->
      ( { model | effects = message :: model.effects }
      , State.Send Message.stepComplete
      )

    ProgramMsg programMsg ->
      model.scenario.subject.update outlet programMsg model.programModel
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


subscriptions : Model model msg -> Sub msg
subscriptions model =
  Subject.subscriptions model.scenario.subject


addIfUnique : List a -> a -> List a
addIfUnique list val =
  if List.member val list then
    list
  else
    list ++ [ val ]
