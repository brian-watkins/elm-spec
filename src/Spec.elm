module Spec exposing
  ( Spec
  , Model
  , Msg
  , Config
  , Expectation
  , given
  , when
  , it
  , suppose
  , update
  , view
  , init
  , subscriptions
  , program
  , browserProgram
  , expect
  )

import Spec.Observer as Observer exposing (Observer, Verdict)
import Spec.Observer.Report as Report
import Spec.Message as Message exposing (Message)
import Spec.Lifecycle as Lifecycle
import Spec.Subject as Subject exposing (Subject)
import Spec.Actual as Actual exposing (Actual)
import Task
import Json.Encode exposing (Value)
import Process
import Html exposing (Html)
import Dict exposing (Dict)
import Procedure.Program
import Procedure
import Procedure.Channel as Channel
import Browser


type Spec model msg =
  Spec
    { subject: Subject model msg
    , conditions: List String
    , steps: List (SpecStep model msg)
    , requirements: List (Requirement model msg)
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


type alias Expectation model msg =
  String -> Config msg -> Spec model msg -> Cmd (Msg msg)


type alias Requirement model msg =
  { description: String
  , expectation: Expectation model msg
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
    , requirements = []
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


it : String -> Expectation model msg -> Spec model msg -> Spec model msg
it description expectation (Spec spec) =
  Spec 
    { spec 
    | requirements = spec.requirements ++
      [ { description = formatObservationDescription description
        , expectation = expectation
        }
      ]
    }


expect : Observer a -> Actual model a -> String -> Config msg -> Spec model msg -> Cmd (Msg msg)
expect observer actual description config (Spec spec) =
  case actual of
    Actual.Model mapper ->
      Procedure.provide spec.subject.model
        |> Procedure.map (mapper >> observer)
        |> Procedure.run ProcedureMsg (Lifecycle << Lifecycle.ObservationComplete description)
    Actual.Effects mapper ->
      Procedure.provide spec.subject.effects
        |> Procedure.map (mapper >> observer)
        |> Procedure.run ProcedureMsg (Lifecycle << Lifecycle.ObservationComplete description)
    Actual.Inquiry message mapper ->
      Channel.open (\key -> config.send <| Observer.inquiry key message)
        |> Channel.connect config.listen
        |> Channel.filter (\key data -> filterForInquiryResult key data)
        |> Channel.acceptOne
        |> Procedure.map (\inquiry ->
          Message.decode Observer.inquiryDecoder inquiry
            |> Maybe.map .message
            |> Maybe.map (mapper >> observer)
            |> Maybe.withDefault (Observer.Reject <| Report.note "Unable to decode inquiry result!")
        )
        |> Procedure.run ProcedureMsg (Lifecycle << Lifecycle.ObservationComplete description)


filterForInquiryResult : String -> Message -> Bool
filterForInquiryResult key message =
  if Message.is "_observer" "inquiryResult" message then
    Message.decode Observer.inquiryDecoder message
      |> Maybe.map .key
      |> Maybe.map (\actual -> actual == key)
      |> Maybe.withDefault False
  else
    False


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
  sendLifecycle Lifecycle.NextStep


sendLifecycle : Lifecycle.Msg -> Cmd (Msg msg)
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
  = ProcedureMsg (Procedure.Program.Msg (Msg msg))
  | ProgramMsg msg
  | SendMessage Message
  | ReceivedEffect Message
  | Lifecycle Lifecycle.Msg


type alias Model model msg =
  { specs: List (Spec model msg)
  , current: Spec model msg
  , procedureModel: Procedure.Program.Model (Msg msg)
  }


view : Model model msg -> Html (Msg msg)
view model =
  subject model.current
    |> Subject.render
    |> Html.map ProgramMsg


receiveLifecycleMessages : Config msg -> Cmd (Msg msg)
receiveLifecycleMessages config =
  Channel.join config.listen
    |> Channel.filter (\_ message ->
      Lifecycle.isLifecycleMessage message
    )
    |> Channel.accept
    |> Procedure.map Lifecycle.toMsg
    |> Procedure.andThen (\msg -> Procedure.fromTask <| (Process.sleep 0 |> Task.andThen (\_ -> Task.succeed msg)))
    |> Procedure.run ProcedureMsg Lifecycle


receiveEffectMessages : Config msg -> Cmd (Msg msg)
receiveEffectMessages config =
  Channel.join config.listen
    |> Channel.filter (\_ message ->
      message.home /= "_spec" && message.home /= "_observer"
    )
    |> Channel.accept
    |> Procedure.run ProcedureMsg ReceivedEffect


update : Config msg -> Msg msg -> Model model msg -> ( Model model msg, Cmd (Msg msg) )
update config msg model =
  case msg of
    ProcedureMsg procMsg ->
      Procedure.Program.update procMsg model.procedureModel
        |> Tuple.mapFirst (\updated -> { model | procedureModel = updated })
    ReceivedEffect message ->
      ( recordEffect message model
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


lifecycleUpdate : Config msg -> Lifecycle.Msg -> Model model msg -> ( Model model msg, Cmd (Msg msg) )
lifecycleUpdate config msg model =
  case msg of
    Lifecycle.Start ->
      ( model, nextStep )
    Lifecycle.StartSteps ->
      ( { model | current = setState Exercise model.current }
      , nextStep
      )
    Lifecycle.NextStep ->
      case specSteps model.current of
        [] ->
          ( { model | current = setState Observe model.current }
          , sendLifecycle Lifecycle.ObserveSubject
          )
        step :: remainingSteps ->
          let
            updatedSpec =
              setSteps remainingSteps model.current
                |> addCondition step.condition
          in
            ( { model | current = updatedSpec }, step.run updatedSpec )
    Lifecycle.NextSpec ->
      let
        updatedModel =
          if specState model.current == Aborted then
            model
          else
            { model | specs = List.append (scenarioSpecs model.current) model.specs }
      in
        case updatedModel.specs of
          [] ->
            ( updatedModel, sendLifecycle Lifecycle.SpecComplete )
          next :: remaining ->
            ( { updatedModel | specs = remaining, current = next }, nextStep )
    Lifecycle.SpecComplete ->
      ( model, config.send Lifecycle.specComplete )
    Lifecycle.ObserveSubject ->
      case specRequirements model.current of
        [] ->
          ( model
          , config.send Lifecycle.observationsComplete
          )
        next :: remaining ->
          ( { model | current = setRequirements remaining model.current }
          , next.expectation next.description config model.current
          )
    Lifecycle.ObservationComplete description verdict ->
      let
        (Spec spec) = model.current
      in
        ( model
        , Cmd.batch
          [ config.send <| Observer.observation spec.conditions description verdict
          , sendLifecycle Lifecycle.ObserveSubject
          ]
        )
    Lifecycle.AbortSpec report ->
      ( { model | current = setState Aborted model.current }
      , Cmd.batch
        [ Observer.Reject report
            |> Observer.observation (conditions model.current) "A spec step failed"
            |> config.send
        , config.send Lifecycle.observationsComplete
        ]
      )


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
  Sub.batch
  [ if specState model.current == Exercise then
      subject model.current
        |> Subject.subscriptions
        |> Sub.map ProgramMsg
    else
      Sub.none
  , Procedure.Program.subscriptions model.procedureModel
  ]


init : Config msg -> List (Spec model msg) -> () -> ( Model model msg, Cmd (Msg msg) )
init config specs _ =
  case specs of
    [] ->
      Elm.Kernel.Debug.todo "No specs!"
    spec :: remaining ->
      ( { specs = remaining, current = spec, procedureModel = Procedure.Program.init }
      , Cmd.batch
        [ receiveLifecycleMessages config
        , receiveEffectMessages config
        ]
      )


program : Config msg -> List (Spec model msg) -> Program () (Model model msg) (Msg msg)
program config specs =
  Platform.worker
    { init = init config specs
    , update = update config
    , subscriptions = subscriptions config
    }


browserProgram : Config msg -> List (Spec model msg) -> Program () (Model model msg) (Msg msg)
browserProgram config specs =
  Browser.element
    { init = init config specs
    , view = view
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


specRequirements : Spec model msg -> List (Requirement model msg)
specRequirements (Spec spec) =
  spec.requirements


setRequirements : List (Requirement model msg) -> Spec model msg -> Spec model msg
setRequirements requirements (Spec spec) =
  Spec { spec | requirements = requirements }


addCondition : String -> Spec model msg -> Spec model msg
addCondition condition (Spec spec) =
  if List.member condition spec.conditions then
    Spec spec
  else
    Spec { spec | conditions = spec.conditions ++ [ condition ] }


conditions : Spec model msg -> List String
conditions (Spec spec) =
  spec.conditions
