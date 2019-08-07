module Spec exposing
  ( Spec
  , Model
  , Msg
  , Config
  , given
  , when
  , it
  , doStep
  , expectModel
  , update
  , init
  , subscriptions
  , messageTagger
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
    , steps: List (Spec model msg -> Cmd (Msg msg))
    , observations: List (Observation model msg)
    }


type alias Observation model msg =
  { description: String
  , observer: Observer (Subject model msg)
  }


given : Subject model msg -> Spec model msg
given specSubject =
  Spec
    { subject = specSubject
    , steps = 
        let
          configCommand =
            if List.isEmpty specSubject.configureEnvironment then
              nextStep
            else
              Cmd.batch
                [ List.map sendMessage specSubject.configureEnvironment
                    |> Cmd.batch
                , sendMessage Message.stepComplete
                ]
        in
          if specSubject.initialCommand == Cmd.none then
            [ \_ -> configCommand ]
          else
            [ \_ -> configCommand
            , \_ -> Cmd.map ProgramMsg specSubject.initialCommand
            ]
    , observations = []
    }


when : List (Subject model msg -> Message) -> Spec model msg -> Spec model msg
when messageSteps (Spec spec) =
  Spec
    { spec 
    | steps =
        messageSteps
          |> List.map (\f -> \s -> subject s |> f |> sendMessage)
          |> List.append spec.steps
    }


it : String -> Observer (Subject model msg) -> Spec model msg -> Spec model msg
it description observer (Spec spec) =
  Spec
    { spec | observations = { description = "it " ++ description, observer = observer } :: spec.observations }


expectModel : Observer model -> Observer (Subject model msg)
expectModel observer specSubject =
  observer specSubject.model


doStep : (Subject model msg -> Message) -> Spec model msg -> Spec model msg
doStep stepper (Spec spec) =
  let
    step = \sp ->
      subject sp
        |> stepper
        |> sendMessage
  in
    Spec
      { spec | steps = step :: spec.steps }


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



---- Program


type alias Config msg =
  { out: Message -> Cmd msg
  }


type Msg msg
  = ProgramMsg msg
  | ReceivedMessage Message
  | SendMessage Message
  | NextStep
  | SpecComplete
  | ObserveSubject


type alias Model model msg =
  { spec: Spec model msg
  }


messageTagger : Message -> Msg msg
messageTagger =
  ReceivedMessage


update : Config (Msg msg) -> Msg msg -> Model model msg -> ( Model model msg, Cmd (Msg msg) )
update config msg model =
  let
    (Spec spec) = model.spec
    specSubject = subject model.spec
  in
  case msg of
    ReceivedMessage specMessage ->
      case specMessage.home of
        "spec" ->
          ( model, nextStep )
        _ ->
          ( { model | spec = Spec { spec | subject = Subject.pushEffect specMessage spec.subject } }
          , sendMessage Message.stepComplete
          )
    NextStep ->
      case spec.steps of
        [] ->
          (model, Task.succeed never |> Task.perform (always ObserveSubject))
        step :: remainingSteps ->
          let
              updatedSpec = Spec { spec | steps = remainingSteps }
          in
            ( { model | spec = updatedSpec }, step updatedSpec )
    SpecComplete ->
      ( model, sendMessage Message.specComplete )
    ProgramMsg programMsg ->
      let
        ( updatedModel, nextCommand ) =
          specSubject.update programMsg specSubject.model
        nextModel =
          { model | spec = Spec { spec | subject = { specSubject | model = updatedModel } } }
      in
        if nextCommand == Cmd.none then
          ( nextModel, sendMessage Message.stepComplete )
        else
          ( nextModel, Cmd.map ProgramMsg nextCommand )
    ObserveSubject ->
      ( model
      , List.map (\observation -> (observation.description, observation.observer <| subject model.spec)) spec.observations
        |> List.map Message.observation
        |> List.map config.out
        |> List.append [ andThenSend SpecComplete ]
        |> Cmd.batch
      )
    SendMessage message ->
      ( model, config.out message )


andThenSend : msg -> Cmd msg
andThenSend msg =
  Process.sleep 0
    |> Task.perform (always msg)


subscriptions : Model model msg -> Sub (Msg msg)
subscriptions model =
  let
    specSubject = subject model.spec
  in
    specSubject.subscriptions specSubject.model
      |> Sub.map ProgramMsg


init : Spec model msg -> () -> ( Model model msg, Cmd (Msg msg) )
init spec _ =
  ( { spec = spec }
  , Cmd.none
  )
