module Spec exposing
  ( Spec
  , Msg(..)
  , Model
  , Config
  , given
  , when
  , send
  , nothing
  , expectModel
  , update
  , init
  , subscriptions
  , messageTagger
  )

import Observer exposing (Observer, Verdict)
import Spec.Message as Message exposing (Message)
import Spec.Program exposing (SpecProgram)
import Task
import Json.Encode exposing (Value)


type Spec model msg =
  Spec
    { model: model
    , update: msg -> model -> ( model, Cmd msg )
    , subscriptions: model -> Sub msg
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
      , subscriptions = program.subscriptions
      , steps =
          if initialCommand == Cmd.none then
            []
          else
            [ \_ -> Cmd.map ProgramMsg initialCommand ]
      }


when : (() -> Spec model msg) -> Spec model msg
when specGenerator =
  specGenerator ()


send : String -> Value -> (() -> Spec model msg) -> (() -> Spec model msg)
send name value specGenerator =
  \_ ->
    let
      (Spec spec) = specGenerator ()
    in
      Spec { spec | steps = (sendSubscriptionStep name value) :: spec.steps }
  

sendSubscriptionStep : String -> Value -> Spec model msg -> Cmd (Msg msg)
sendSubscriptionStep name value _ =
  Message.sendSubscription name value
    |> Task.succeed 
    |> Task.perform SendMessage


nothing : (() -> Spec model msg) -> (() -> Spec model msg)
nothing =
  identity


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
  | SendMessage Message 
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
      ( model, config.out <| Message.observation verdict )
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
