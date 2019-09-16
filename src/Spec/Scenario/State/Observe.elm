module Spec.Scenario.State.Observe exposing
  ( Model
  , init
  , view
  , update
  )

import Spec.Scenario exposing (Scenario)
import Spec.Scenario.State as State exposing (Msg(..), Command)
import Spec.Message exposing (Message)
import Spec.Observation.Expectation as Expectation exposing (Judgment(..))
import Spec.Observation.Message as Message
import Spec.Observation exposing (Observation)
import Spec.Scenario.State.Exercise as Exercise
import Html exposing (Html)


type alias Model model msg =
  { scenario: Scenario model msg
  , conditionsApplied: List String
  , programModel: model
  , effects: List Message
  , observations: List (Observation model)
  , expectationModel: Expectation.Model model
  , currentDescription: String
  }


init : Exercise.Model model msg -> Model model msg
init exerciseModel =
  { scenario = exerciseModel.scenario
  , conditionsApplied = exerciseModel.conditionsApplied
  , programModel = exerciseModel.programModel
  , effects = exerciseModel.effects
  , observations = exerciseModel.scenario.observations
  , expectationModel = Expectation.init
  , currentDescription = ""
  }


view : Model model msg -> Html msg
view model =
  model.scenario.subject.view model.programModel


update : Msg msg -> Model model msg -> ( Model model msg, Command (Msg msg) )
update msg model =
  case msg of
    ReceivedMessage message ->
      Expectation.update (Expectation.HandleInquiry message) model.expectationModel
        |> Tuple.mapFirst (\updated -> { model | currentDescription = "", expectationModel = updated })
        |> Tuple.mapSecond (sendExpectationMessage model)

    ProgramMsg programMsg ->
      ( model, State.Do Cmd.none )
    
    Continue ->
      case model.observations of
        [] ->
          ( model, State.Transition )
        observation :: remaining ->
          Expectation.update (Expectation.Run (toObservationContext model) observation.expectation)
            model.expectationModel
          |> Tuple.mapFirst (\updated ->
              { model
              | currentDescription = observation.description
              , expectationModel = updated
              , observations = remaining 
              }
            )
          |> mapTuple (\updated command -> ( updated, sendExpectationMessage updated command ))
    
    Abort _ ->
      ( model, State.Do Cmd.none )


sendExpectationMessage : Model model msg -> Expectation.Command -> Command (Msg msg)
sendExpectationMessage model result =
  case result of
    Expectation.Done verdict ->
      Message.observation model.conditionsApplied model.currentDescription verdict
        |> State.Send
    Expectation.Send message ->
      State.Send message


toObservationContext : Model model msg -> Expectation.Context model
toObservationContext model =
  { model = model.programModel
  , effects = model.effects
  }


mapTuple : (a -> b -> (c, d)) -> (a, b) -> (c, d)
mapTuple mapper ( first, second ) =
  mapper first second
