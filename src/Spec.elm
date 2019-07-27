module Spec exposing
  ( Spec
  , Msg(..)
  , Model
  , Config
  , given
  , begin
  , expectModel
  , update
  , init
  , messageTagger
  )

import Observer exposing (Observer, Verdict)
import Spec.Message exposing (Message)
import Spec.Program exposing (SpecProgram)
import Task


type Spec model msg =
  Spec
    { model: model
    , update: msg -> model -> ( model, Cmd msg )
    , steps: List (Spec model msg -> Cmd (Msg msg))
    }


given : SpecProgram model msg -> Spec model msg
given program =
  let
    ( initialModel, initialCommand ) = program.init ()
  in
    Spec
      { model = initialModel
      , update = program.update
      , steps =
          if initialCommand == Cmd.none then
            []
          else
            [ \_ -> Cmd.map ProgramMsg initialCommand ]
      }


begin : (() -> Spec model msg) -> Spec model msg
begin thunk =
  thunk ()


expectModel : Observer model -> Spec model msg -> Spec model msg
expectModel observer (Spec spec) =
  Spec
    { spec | steps = spec.steps ++ [ expectModelStep observer ] }


expectModelStep : Observer model -> Spec model msg -> Cmd (Msg msg)
expectModelStep observer (Spec spec) =
  observer spec.model
    |> Task.succeed
    |> Task.perform ObservationComplete



---- Program


type alias Config msg =
  { out: Message -> Cmd msg
  }


type Msg msg
  = ProgramMsg msg
  | ObservationComplete Verdict
  | ReceivedMessage Message
  | NextStep


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
      ( model, Task.succeed never |> Task.perform (always NextStep) )
    NextStep ->
      case spec.steps of
        [] ->
          (model, Cmd.none)
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
        , Task.succeed never |> Task.perform (always NextStep)
        )
    ObservationComplete verdict ->
      ( model, config.out <| Spec.Message.observation verdict )


init : Spec model msg -> () -> ( Model model msg, Cmd (Msg msg) )
init spec _ =
  ( { spec = spec }
  , Cmd.none
  )
