module Spec exposing
  ( Spec
  , Model
  , Config
  , given
  , when
  , it
  , sendMessage
  , addStep
  , doStep
  , effects
  , nothing
  , expectModel
  , update
  , init
  , subscriptions
  , messageTagger
  )

import Observer exposing (Observer, Verdict)
import Spec.Message as Message exposing (Message)
import Spec.Subject exposing (Subject)
import Spec.Types exposing (..)
import Task
import Json.Encode exposing (Value)


type Spec model msg =
  Spec
    { model: model
    , update: msg -> model -> ( model, Cmd msg )
    , subscriptions: model -> Sub msg
    , steps: List (Spec model msg -> Cmd (Msg msg))
    , effects: List Message
    , observations: List (Observation model msg)
    }


type alias Observation model msg =
  { description: String
  , observer: Observer (Spec model msg)
  }


given : Subject model msg -> Spec model msg
given program =
  let
    ( initialModel, initialCommand ) = program.init ()
  in
    Spec
      { model = initialModel
      , update = program.update
      , subscriptions = program.subscriptions
      , steps =
          let
            configCommand =
              if program.configureEnvironment == Cmd.none then
                next
              else
                Cmd.batch
                [ program.configureEnvironment
                , sendMessage Message.stepComplete
                ]
          in
          if initialCommand == Cmd.none then
            [ \_ -> configCommand ]
          else
            [ \_ -> configCommand
            , \_ -> Cmd.map ProgramMsg initialCommand
            ]
      , effects = []
      , observations = []
      }


when : (() -> Spec model msg) -> Spec model msg
when specGenerator =
  specGenerator ()


it : String -> Observer (Spec model msg) -> Spec model msg -> Spec model msg
it description observer (Spec spec) =
  Spec
    { spec | observations = { description = "it " ++ description, observer = observer } :: spec.observations }


expectModel : Observer model -> Observer (Spec model msg)
expectModel observer (Spec spec) =
  observer spec.model


doStep : (Spec model msg -> Cmd (Msg msg)) -> (() -> Spec model msg) -> (() -> Spec model msg)
doStep stepper specGenerator =
  \_ ->
    let
      (Spec spec) = specGenerator ()
    in
      Spec { spec | steps = stepper :: spec.steps }


effects : Spec model msg -> List Message
effects (Spec spec) =
  spec.effects


sendMessage : Message -> Cmd (Msg msg)
sendMessage message =
  Task.succeed message
    |> Task.perform SendMessage


nothing : (() -> Spec model msg) -> (() -> Spec model msg)
nothing =
  identity


addStep : (Spec model msg -> Cmd (Msg msg)) -> Spec model msg -> Spec model msg
addStep step (Spec spec) =
  Spec
    { spec | steps = spec.steps ++ [ step ] }


next : Cmd (Msg msg)
next =
  Task.succeed never
    |> Task.perform (always NextStep)



---- Program


type alias Config msg =
  { out: Message -> Cmd msg
  }


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
  in
  case msg of
    ReceivedMessage specMessage ->
      case specMessage.home of
        "spec" ->
          ( model, next )
        _ ->
          ( { model | spec = Spec { spec | effects = specMessage :: spec.effects } }
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
        ( updatedModel, _ ) = spec.update programMsg spec.model
      in
        ( { model | spec = Spec { spec | model = updatedModel } }
        , next
        )
    ObserveSubject ->
      ( model
      , List.map (\observation -> (observation.description, observation.observer model.spec)) spec.observations
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
    (Spec spec) = model.spec
  in
    spec.subscriptions spec.model
      |> Sub.map ProgramMsg


init : Spec model msg -> () -> ( Model model msg, Cmd (Msg msg) )
init spec _ =
  ( { spec = spec }
  , Cmd.none
  )
