module Spec exposing
  ( Spec
  , Model
  , Msg
  , Config
  , given
  , when
  , it
  , suppose
  , expectModel
  , update
  , init
  , subscriptions
  , program
  )

import Observer exposing (Observer, Verdict)
import Spec.Message as Message exposing (Message)
import Spec.Lifecycle as Lifecycle
import Spec.Subject as Subject exposing (Subject)
import Task
import Json.Encode exposing (Value)
import Process


type Spec model msg =
  Spec
    { subject: Subject model msg
    , conditions: List String
    , steps: List (Spec model msg -> Cmd (Msg msg))
    , observations: List (Observation model msg)
    , scenarios: List (Subject model msg -> Spec model msg)
    , state: SpecState
    }


type SpecState
  = Configure
  | Exercise
  | Observe


type alias Observation model msg =
  { description: String
  , observer: Observer (Subject model msg)
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
        in
          if specSubject.initialCommand == Cmd.none then
            [ \_ -> configCommand ]
          else
            [ \_ -> configCommand
            , \_ -> Cmd.map ProgramMsg specSubject.initialCommand
            ]
    , observations = []
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
          |> List.append spec.steps
    , conditions =
        List.append spec.conditions [ formatCondition condition ]
    }


it : String -> Observer (Subject model msg) -> Spec model msg -> Spec model msg
it description observer (Spec spec) =
  Spec
    { spec
    | observations =
        { description = formatObservationDescription description
        , observer = observer
        } :: spec.observations
    }


suppose : (Subject model msg -> Spec model msg) -> Spec model msg -> Spec model msg
suppose generator (Spec spec) =
  Spec
    { spec | scenarios = generator :: spec.scenarios }


expectModel : Observer model -> Observer (Subject model msg)
expectModel observer specSubject =
  observer specSubject.model


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


subject : Spec model msg -> Subject model msg
subject (Spec spec) =
  spec.subject


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
  { send: Message -> Cmd msg
  , listen: (Message -> msg) -> Sub msg
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


type alias Model model msg =
  { specs: List (Spec model msg)
  , current: Spec model msg
  }


update : Config (Msg msg) -> Msg msg -> Model model msg -> ( Model model msg, Cmd (Msg msg) )
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
      let
        (Spec spec) = model.current
      in
        Subject.update programMsg spec.subject
          |> Tuple.mapFirst (\updatedSubject -> { model | current = Spec { spec | subject = updatedSubject } })
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
  let
    (Spec spec) = model.current
  in
    { model | current = Spec { spec | subject = Subject.pushEffect specMessage spec.subject } }


lifecycleUpdate : Config (Msg msg) -> LifecycleMsg -> Model model msg -> ( Model model msg, Cmd (Msg msg) )
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
            updatedSpec = setSteps remainingSteps model.current
          in
            ( { model | current = updatedSpec }, step updatedSpec )
    NextSpec ->
      case model.specs of
        [] ->
          ( model, sendLifecycle SpecComplete )
        next :: remaining ->
          ( { model | specs = remaining, current = next }, nextStep )
    SpecComplete ->
      ( model, config.send Lifecycle.specComplete )
    ObserveSubject ->
      ( model, sendObservations config model.current )


sendObservations : Config (Msg msg) -> Spec model msg -> Cmd (Msg msg)
sendObservations config (Spec spec) =
  List.map (runObservation spec.subject) spec.observations
    |> List.map (Lifecycle.observation spec.conditions)
    |> List.map config.send
    |> (++) [ config.send Lifecycle.observationsComplete ]
    |> Cmd.batch


runObservation : Subject model msg -> Observation model msg -> (String, Verdict)
runObservation specSubject observation =
  ( observation.description
  , observation.observer specSubject
  )


handleLifecycleCommand : Model model msg -> Lifecycle.Command -> ( Model model msg, Cmd (Msg msg) )
handleLifecycleCommand model command =
  case command of
    Lifecycle.Start ->
      ( model, nextStep )
    Lifecycle.NextSpec ->
      ( { model | specs = List.append (scenarioSpecs model.current) model.specs }
      , sendLifecycle NextSpec
      )
    Lifecycle.StartSteps ->
      ( { model | current = setState Exercise model.current }, nextStep )
    Lifecycle.NextStep ->
      ( model, nextStep )


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


subscriptions : Config (Msg msg) -> Model model msg -> Sub (Msg msg)
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


program : Config (Msg msg) -> List (Spec model msg) -> Program () (Model model msg) (Msg msg)
program config specs =
  Platform.worker
    { init = init specs
    , update = update config
    , subscriptions = subscriptions config
    }



--- Helpers


specState : Spec model msg -> SpecState
specState (Spec spec) =
  spec.state


setState : SpecState -> Spec model msg -> Spec model msg
setState state (Spec spec) =
  Spec { spec | state = state }


specSteps : Spec model msg -> List (Spec model msg -> Cmd (Msg msg))
specSteps (Spec spec) =
  spec.steps


setSteps : List (Spec model msg -> Cmd (Msg msg)) -> Spec model msg -> Spec model msg
setSteps steps (Spec spec) =
  Spec { spec | steps = steps }
