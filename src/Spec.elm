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
    }


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
              sendMessage Message.configureComplete
            else
              Cmd.batch
                [ List.map sendMessage specSubject.configureEnvironment
                    |> Cmd.batch
                , sendMessage Message.configureComplete
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
  Task.succeed never
    |> Task.perform (always NextStep)


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
  | NextStep
  | NextSpec
  | SpecComplete
  | ObserveSubject


type alias Model model msg =
  { specs: List (Spec model msg)
  , current: Spec model msg
  , running: Bool
  }


update : Config (Msg msg) -> Msg msg -> Model model msg -> ( Model model msg, Cmd (Msg msg) )
update config msg model =
  let
    (Spec spec) = model.current
  in
  case msg of
    ReceivedMessage specMessage ->
      case specMessage.home of
        "_spec" ->
          Message.incoming specMessage
            |> Maybe.map (handleIncomingSpecMessage model)
            |> Maybe.withDefault (model, Cmd.none)
        _ ->
          ( { model | current = Spec { spec | subject = Subject.pushEffect specMessage spec.subject } }
          , config.send Message.stepComplete
          )
    NextStep ->
      case spec.steps of
        [] ->
          ({ model | running = False }, andThenSend ObserveSubject )
        step :: remainingSteps ->
          let
            updatedSpec = Spec { spec | steps = remainingSteps }
          in
            ( { model | current = updatedSpec }, step updatedSpec )
    NextSpec ->
      case model.specs of
        [] ->
          ( model, Task.succeed never |> Task.perform (always SpecComplete) )
        next :: remaining ->
          ( { model | specs = remaining, current = next }, nextStep )
    SpecComplete ->
      ( model, config.send Message.specComplete )
    ProgramMsg programMsg ->
      Subject.update programMsg spec.subject
        |> Tuple.mapFirst (\updatedSubject -> { model | current = Spec { spec | subject = updatedSubject } })
        |> Tuple.mapSecond (\nextCommand -> 
          if nextCommand == Cmd.none then
            config.send Message.stepComplete
          else
            Cmd.map ProgramMsg nextCommand
        )
    ObserveSubject ->
      ( model, sendObservations config model.current )
    SendMessage message ->
      ( model, config.send message )


sendObservations : Config (Msg msg) -> Spec model msg -> Cmd (Msg msg)
sendObservations config (Spec spec) =
  List.map (runObservation spec.subject) spec.observations
    |> List.map (Message.observation spec.conditions)
    |> List.map config.send
    |> (++) [ config.send Message.observationsComplete ]
    |> Cmd.batch


runObservation : Subject model msg -> Observation model msg -> (String, Verdict)
runObservation specSubject observation =
  ( observation.description
  , observation.observer specSubject
  )


handleIncomingSpecMessage : Model model msg -> Message.IncomingMessageType -> ( Model model msg, Cmd (Msg msg) )
handleIncomingSpecMessage model messageType =
  case messageType of
    Message.Start ->
      ( model, nextStep )
    Message.NextSpec ->
      ( { model | specs = List.append (scenarioSpecs model.current) model.specs }
      , Task.succeed never |> Task.perform (always NextSpec)
      )
    Message.StartSteps ->
      ( { model | running = True }, nextStep )
    Message.NextStep ->
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


andThenSend : msg -> Cmd msg
andThenSend msg =
  Process.sleep 0
    |> Task.perform (always msg)


subscriptions : Config (Msg msg) -> Model model msg -> Sub (Msg msg)
subscriptions config model =
  let
    specSubject = subject model.current
  in
    Sub.batch
    [ if model.running == True then
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
      ( { specs = remaining, current = spec, running = False }
      , Cmd.none
      )


program : Config (Msg msg) -> List (Spec model msg) -> Program () (Model model msg) (Msg msg)
program config specs =
  Platform.worker
    { init = init specs
    , update = update config
    , subscriptions = subscriptions config
    }