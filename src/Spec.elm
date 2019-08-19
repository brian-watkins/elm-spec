module Spec exposing
  ( Spec
  , Model
  , Msg
  , Config
  , given
  , when
  , it
  , suppose
  , update
  , view
  , init
  , subscriptions
  , program
  )

import Spec.Observer as Observer exposing (Observer, Verdict)
import Spec.Message as Message exposing (Message)
import Spec.Context exposing (Context)
import Spec.Lifecycle as Lifecycle
import Spec.Subject as Subject exposing (Subject)
import Task
import Json.Encode exposing (Value)
import Process
import Html exposing (Html)
import Dict exposing (Dict)


type Spec model msg =
  Spec
    { subject: Subject model msg
    , conditions: List String
    , steps: List (SpecStep model msg)
    , observations: Dict String (Observation model)
    , scenarios: List (Subject model msg -> Spec model msg)
    , state: SpecState
    }


type alias SpecStep model msg =
  { run: Spec model msg -> Cmd (Msg msg)
  , condition: String
  }


type SpecState
  = Configure
  | Exercise
  | Observe
  | Aborted


type alias Observation model =
  { key: String
  , description: String
  , observer: Observer (Context model)
  }


given : String -> Subject model msg -> Spec model msg
given description specSubject =
  Spec
    { subject = specSubject
    , steps = 
        let
          configCommand =
            if List.isEmpty specSubject.configureEnvironment then
              sendMessage Lifecycle.configureComplete
            else
              Cmd.batch
                [ List.map sendMessage specSubject.configureEnvironment
                    |> Cmd.batch
                , sendMessage Lifecycle.configureComplete
                ]
          toInitialStep stepFunction =
            { condition = formatGivenDescription description, run = stepFunction }
        in
          if specSubject.initialCommand == Cmd.none then
            [ toInitialStep <| \_ -> configCommand ]
          else
            [ toInitialStep <| \_ -> configCommand
            , toInitialStep <| \_ -> Cmd.map ProgramMsg specSubject.initialCommand
            ]
    , observations = Dict.empty
    , conditions = [ formatGivenDescription description ]
    , scenarios = []
    , state = Configure
    }


when : String -> List (Subject model msg -> Message) -> Spec model msg -> Spec model msg
when condition messageSteps (Spec spec) =
  Spec
    { spec 
    | steps =
        messageSteps
          |> List.map (\f -> \s -> subject s |> f |> sendMessage)
          |> List.map (\step -> { run = step, condition = formatCondition condition })
          |> List.append spec.steps
    }


it : String -> Observer (Context model) -> Spec model msg -> Spec model msg
it description observer (Spec spec) =
  let
    observationKey = "Observer-" ++ (String.fromInt <| Dict.size spec.observations)
  in
    Spec
      { spec
      | observations =
          spec.observations
            |> Dict.insert observationKey
                { key = observationKey
                , description = formatObservationDescription description
                , observer = observer
                }
      }


suppose : (Subject model msg -> Spec model msg) -> Spec model msg -> Spec model msg
suppose generator (Spec spec) =
  Spec
    { spec | scenarios = generator :: spec.scenarios }


sendMessage : Message -> Cmd (Msg msg)
sendMessage message =
  Task.succeed message
    |> Task.perform SendMessage


nextStep : Cmd (Msg msg)
nextStep =
  sendLifecycle NextStep


sendLifecycle : LifecycleMsg -> Cmd (Msg msg)
sendLifecycle lifecycleMsg =
  Task.succeed never
    |> Task.perform (always <| Lifecycle lifecycleMsg)


formatGivenDescription : String -> String
formatGivenDescription description =
  "Given " ++ description


formatCondition : String -> String
formatCondition condition =
  "When " ++ condition


formatObservationDescription : String -> String
formatObservationDescription description =
  "It " ++ description



---- Program


type alias Config msg =
  { send: Message -> Cmd (Msg msg)
  , outlet: Message -> Cmd msg
  , listen: (Message -> (Msg msg)) -> Sub (Msg msg)
  }


type Msg msg
  = ProgramMsg msg
  | ReceivedMessage Message
  | SendMessage Message
  | Lifecycle LifecycleMsg


type LifecycleMsg
  = NextStep
  | NextSpec
  | SpecComplete
  | ObserveSubject
  | AbortSpec String


type alias Model model msg =
  { specs: List (Spec model msg)
  , current: Spec model msg
  }


view : Model model msg -> Html (Msg msg)
view model =
  let
    (Spec spec) = model.current
  in
    spec.subject.view spec.subject.model
      |> Html.map ProgramMsg


update : Config msg -> Msg msg -> Model model msg -> ( Model model msg, Cmd (Msg msg) )
update config msg model =
  case msg of
    ReceivedMessage specMessage ->
      if Lifecycle.isLifecycleMessage specMessage then
        Lifecycle.commandFrom specMessage
          |> Maybe.map (handleLifecycleCommand model)
          |> Maybe.withDefault (model, Cmd.none)
      else
        ( recordEffect specMessage model
        , config.send Lifecycle.stepComplete
        )
    SendMessage message ->
      ( model, config.send message )
    ProgramMsg programMsg ->
      subject model.current
        |> Subject.update config.outlet programMsg
        |> Tuple.mapFirst (\updated -> { model | current = mapSubject (always updated) model.current })
        |> Tuple.mapSecond (\nextCommand ->
          if nextCommand == Cmd.none then
            config.send Lifecycle.stepComplete
          else
            Cmd.map ProgramMsg nextCommand
        )
    Lifecycle lifecycleMsg ->
      lifecycleUpdate config lifecycleMsg model


recordEffect : Message -> Model model msg -> Model model msg
recordEffect specMessage model =
  { model | current = mapSubject (Subject.pushEffect specMessage) model.current }


lifecycleUpdate : Config msg -> LifecycleMsg -> Model model msg -> ( Model model msg, Cmd (Msg msg) )
lifecycleUpdate config msg model =
  case msg of
    NextStep ->
      case specSteps model.current of
        [] ->
          ( { model | current = setState Observe model.current }
          , sendLifecycle ObserveSubject
          )
        step :: remainingSteps ->
          let
            updatedSpec =
              setSteps remainingSteps model.current
                |> addCondition step.condition
          in
            ( { model | current = updatedSpec }, step.run updatedSpec )
    NextSpec ->
      case model.specs of
        [] ->
          ( model, sendLifecycle SpecComplete )
        next :: remaining ->
          ( { model | specs = remaining, current = next }, nextStep )
    SpecComplete ->
      ( model, config.send Lifecycle.specComplete )
    ObserveSubject ->
      let
        (Spec spec) = model.current
        ( remainingObservations, command ) = processObservers config model.current spec.observations
      in
        if Dict.isEmpty remainingObservations then
          ( { model | current = Spec { spec | observations = Dict.empty } }
          , Cmd.batch [ command, config.send Lifecycle.observationsComplete ]
          )
        else
          ( { model | current = Spec { spec | observations = remainingObservations } }
          , command
          )
    AbortSpec reason ->
      let
        (Spec spec) = model.current
      in
        ( model
        , Cmd.batch
          [ config.send <| Observer.observation spec.conditions "A spec step failed" <| Observer.Reject reason
          , config.send Lifecycle.observationsComplete
          ]
        )


processObservers : Config msg -> Spec model msg -> Dict String (Observation model) -> (Dict String (Observation model), Cmd (Msg msg))
processObservers config (Spec spec) =
  (Dict.empty, Cmd.none)
    |> Dict.foldl (\key observation (remaining, command) ->
      case observation.observer <| Subject.contextForObservation observation.key spec.subject of
        Observer.Inquire message ->
          ( Dict.insert key observation remaining
          , config.send <| Observer.inquiry observation.key message
          )
        Observer.Render verdict ->
          ( remaining
          , Cmd.batch 
            [ Observer.observation spec.conditions observation.description verdict
                |> config.send
            , command
            ]
          )
    )


handleLifecycleCommand : Model model msg -> Lifecycle.Command -> ( Model model msg, Cmd (Msg msg) )
handleLifecycleCommand model command =
  case command of
    Lifecycle.Start ->
      ( model, nextStep )
    Lifecycle.NextSpec ->
      if specState model.current == Aborted then
        ( model, sendLifecycle NextSpec )
      else
        ( { model | specs = List.append (scenarioSpecs model.current) model.specs }
        , sendLifecycle NextSpec
        )
    Lifecycle.StartSteps ->
      ( { model | current = setState Exercise model.current }, nextStep )
    Lifecycle.NextStep ->
      ( model, nextStep )
    Lifecycle.AbortSpec reason ->
      ( { model | current = setState Aborted model.current }, sendLifecycle <| AbortSpec reason )


scenarioSpecs : Spec model msg -> List (Spec model msg)
scenarioSpecs (Spec spec) =
  spec.scenarios
    |> List.map (\generator ->
      let
        (Spec generatedSpec) = generator spec.subject
      in
        Spec
          { generatedSpec | conditions = List.append spec.conditions generatedSpec.conditions }
    )


subscriptions : Config msg -> Model model msg -> Sub (Msg msg)
subscriptions config model =
  let
    specSubject = subject model.current
  in
    Sub.batch
    [ if specState model.current == Exercise then
        specSubject.subscriptions specSubject.model
          |> Sub.map ProgramMsg
      else
        Sub.none
    , config.listen ReceivedMessage
    ]


init : List (Spec model msg) -> () -> ( Model model msg, Cmd (Msg msg) )
init specs _ =
  case specs of
    [] ->
      Elm.Kernel.Debug.todo "No specs!"
    spec :: remaining ->
      ( { specs = remaining, current = spec }
      , Cmd.none
      )


program : Config msg -> List (Spec model msg) -> Program () (Model model msg) (Msg msg)
program config specs =
  Platform.worker
    { init = init specs
    , update = update config
    , subscriptions = subscriptions config
    }



--- Helpers


subject : Spec model msg -> Subject model msg
subject (Spec spec) =
  spec.subject


mapSubject : (Subject model msg -> Subject model msg) -> Spec model msg -> Spec model msg
mapSubject mapper (Spec spec) =
  Spec { spec | subject = mapper spec.subject }


specState : Spec model msg -> SpecState
specState (Spec spec) =
  spec.state


setState : SpecState -> Spec model msg -> Spec model msg
setState state (Spec spec) =
  Spec { spec | state = state }


specSteps : Spec model msg -> List (SpecStep model msg)
specSteps (Spec spec) =
  spec.steps


setSteps : List (SpecStep model msg) -> Spec model msg -> Spec model msg
setSteps steps (Spec spec) =
  Spec { spec | steps = steps }


addCondition : String -> Spec model msg -> Spec model msg
addCondition condition (Spec spec) =
  if List.member condition spec.conditions then
    Spec spec
  else
    Spec { spec | conditions = spec.conditions ++ [ condition ] }