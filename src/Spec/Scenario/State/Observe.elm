module Spec.Scenario.State.Observe exposing
  ( Model
  , init
  , view
  , update
  )

import Spec.Scenario.Internal as Internal exposing (Scenario, Observation)
import Spec.Setup.Internal as Internal exposing (Subject)
import Spec.Scenario.State as State exposing (Msg(..), Command, Actions)
import Spec.Message exposing (Message)
import Spec.Observer.Expectation as Expectation exposing (Judgment(..))
import Spec.Observer.Message as Message
import Spec.Scenario.State.Exercise as Exercise
import Html exposing (Html)
import Browser exposing (Document)


type alias Model model msg =
  { scenario: Scenario model msg
  , subject: Subject model msg
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
  , subject = exerciseModel.subject
  , conditionsApplied = exerciseModel.conditionsApplied
  , programModel = exerciseModel.programModel
  , effects = exerciseModel.effects
  , observations = exerciseModel.scenario.observations
  , expectationModel = Expectation.init
  , currentDescription = ""
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
      Expectation.update (Expectation.HandleInquiry message) model.expectationModel
        |> Tuple.mapFirst (\updated -> { model | currentDescription = "", expectationModel = updated })
        |> Tuple.mapSecond (sendExpectationMessage actions model)

    ProgramMsg programMsg ->
      ( model, State.Do Cmd.none )
    
    Continue ->
      case model.observations of
        [] ->
          ( model, State.Transition <| actions.complete )
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
          |> mapTuple (\updated command -> ( updated, sendExpectationMessage actions updated command ))
    
    Abort report ->
      ( model
      , State.abortWith actions
          (model.conditionsApplied ++ [ model.currentDescription ]) "Unable to complete observation" report
      )

    OnUrlChange url ->
      ( model, State.Do Cmd.none )

    OnUrlRequest request ->
      ( model, State.Do Cmd.none )


sendExpectationMessage : Actions msg programMsg -> Model model programMsg -> Expectation.Command -> Command msg
sendExpectationMessage actions model result =
  case result of
    Expectation.Done verdict ->
      Message.observation model.conditionsApplied model.currentDescription verdict
        |> State.send actions
    Expectation.Send message ->
      State.send actions message


toObservationContext : Model model msg -> Expectation.Context model
toObservationContext model =
  { model = model.programModel
  , effects = model.effects
  }


mapTuple : (a -> b -> (c, d)) -> (a, b) -> (c, d)
mapTuple mapper ( first, second ) =
  mapper first second
