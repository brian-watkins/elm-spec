module Spec exposing
  ( Spec
  , Msg(..)
  , Model
  , Config
  , given
  , expectModel
  , update
  , init
  , messageTagger
  )

import Observer exposing (Observer, Verdict)
import Spec.Message exposing (Message)
import Task


type Spec model msg =
  Spec
    { model: model
    , update: msg -> model -> ( model, Cmd msg )
    , steps: List (Spec model msg -> Cmd (Msg msg))
    }


given : model -> (msg -> model -> ( model, Cmd msg )) -> Spec model msg
given programModel programUpdate =
  Spec
    { model = programModel
    , update = programUpdate
    , steps = []
    }


expectModel : Observer model -> Spec model msg -> Spec model msg
expectModel matcher (Spec spec) =
  Spec
    { spec | steps = spec.steps ++ [ \(Spec s) -> Task.succeed (matcher s.model) |> Task.perform ObservationComplete ] }



---- Program


type alias Config msg =
  { out: Message -> Cmd msg
  }


type Msg msg
  = ProgramMsg msg
  | ObservationComplete Verdict
  | ReceivedMessage Message


type alias Model model msg =
  { spec: Spec model msg
  }


messageTagger : Message -> Msg msg
messageTagger =
  ReceivedMessage


update : Config (Msg msg) -> Msg msg -> Model model msg -> ( Model model msg, Cmd (Msg msg) )
update config msg model =
  case msg of
    ReceivedMessage specMessage ->
      let
        (Spec spec) = model.spec
      in
        case spec.steps of
          [] ->
            (model, Cmd.none)
          nextStep :: remainingSteps ->
            let
                updatedSpec = Spec { spec | steps = remainingSteps }
            in
              ( { model | spec = updatedSpec }, nextStep updatedSpec )
    ProgramMsg programMsg ->
      ( model, Cmd.none )
    ObservationComplete verdict ->
      ( model, config.out <| Spec.Message.observation verdict )


init : Spec model msg -> () -> ( Model model msg, Cmd (Msg msg) )
init spec _ =
  ( { spec = spec }
  , Cmd.none
  )
