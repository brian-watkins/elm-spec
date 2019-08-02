module Spec exposing
  ( Spec
  , Model
  , Msg
  , Config
  , given
  , when
  , it
  , doStep
  , nothing
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
              next
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


when : Spec model msg -> Spec model msg
when =
  identity


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


nothing : Spec model msg -> Spec model msg
nothing =
  identity


next : Cmd (Msg msg)
next =
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
          ( model, next )
        _ ->
          ( { model | spec = Spec { spec | subject = Subject.pushEffect specMessage spec.subject } }
          , sendMessage Message.stepComplete
          )
    NextStep ->
      case spec.steps of
        [] ->
          (model, Task.succeed never |> Task.perform (always ObserveSubject))
        nextStep :: remainingSteps ->
          let
              updatedSpec = Spec { spec | steps = remainingSteps }
          in
            ( { model | spec = updatedSpec }, nextStep updatedSpec )
    ProgramMsg programMsg ->
      let
        ( updatedModel, _ ) = specSubject.update programMsg specSubject.model
      in
        ( { model | spec = Spec { spec | subject = { specSubject | model = updatedModel } } }
        , next
        )
    ObserveSubject ->
      ( model
      , List.map (\observation -> (observation.description, observation.observer <| subject model.spec)) spec.observations
        |> List.map Message.observation
        |> List.head
        |> Maybe.map config.out
        |> Maybe.withDefault Cmd.none
      )
    SendMessage message ->
      ( model, config.out message )


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
