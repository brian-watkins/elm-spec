module Spec exposing
  ( Spec
  , describe
  , Model, Msg, Config
  , Flags, update, view, init, subscriptions
  , program
  , browserProgram
  , onUrlRequest, onUrlChange
  )

import Spec.Message as Message exposing (Message)
import Spec.Scenario as Scenario exposing (Scenario)
import Spec.Scenario.Message as Message
import Spec.Scenario.Program as ScenarioProgram
import Spec.Scenario.State as ScenarioProgram
import Spec.Observation.Message as Message
import Spec.Helpers exposing (mapDocument)
import Task
import Html exposing (Html)
import Browser exposing (UrlRequest, Document)
import Browser.Navigation exposing (Key)
import Json.Encode as Encode
import Json.Decode as Json
import Url exposing (Url)


type Spec model msg =
  Spec
    (List (Scenario model msg))


describe : String -> List (Scenario model msg) -> Spec model msg
describe description scenarios =
  scenarios
    |> List.map (Scenario.describing description)
    |> Spec


---- Program


type alias Config msg =
  { send: Message -> Cmd (Msg msg)
  , outlet: Message -> Cmd msg
  , listen: (Message -> Msg msg) -> Sub (Msg msg)
  }


type alias Flags =
  { tags: List String
  }


type Msg msg
  = ScenarioMsg (ScenarioProgram.Msg msg)
  | SendMessage Message
  | RunNextScenario
  | ReceivedMessage Message


type alias Model model msg =
  { scenarios: List (Scenario model msg)
  , scenarioModel: ScenarioProgram.Model model msg
  , key: Maybe Key
  }


view : Model model msg -> Document (Msg msg)
view model =
  ScenarioProgram.view model.scenarioModel
    |> mapDocument ScenarioMsg


update : Config msg -> Msg msg -> Model model msg -> ( Model model msg, Cmd (Msg msg) )
update config msg model =
  case msg of
    RunNextScenario ->
      case model.scenarios of
        [] ->
          ( model, config.send specComplete )
        scenario :: remaining ->
          ScenarioProgram.start (scenarioConfig config) model.key scenario
            |> Tuple.mapFirst (\updated -> { model | scenarioModel = updated, scenarios = remaining })
    ScenarioMsg scenarioMsg ->
      ScenarioProgram.update (scenarioConfig config) scenarioMsg model.scenarioModel
        |> Tuple.mapFirst (\updated -> { model | scenarioModel = updated })
    SendMessage message ->
      ( model, config.send message )
    ReceivedMessage message ->
      if Message.belongsTo "_spec" message then
        handleSpecMessage config model message
      else
        update config (ScenarioMsg <| ScenarioProgram.receivedMessage message) model


handleSpecMessage : Config msg -> Model model msg -> Message -> ( Model model msg, Cmd (Msg msg) )
handleSpecMessage config model message =
  Message.decode Json.string message
    |> Maybe.map (\state ->
      case state of
        "FINISH" ->
          ( { model | scenarioModel = ScenarioProgram.finishScenario model.scenarioModel }
          , stopSpecSuiteRun
          )
        _ ->
          update config RunNextScenario model
    )
    |> Maybe.withDefault ( model, Cmd.none )


specComplete : Message
specComplete =
  { home = "_spec"
  , name = "state"
  , body = Encode.string "COMPLETE"
  }


specFinished : Message
specFinished =
  { home = "_spec"
  , name = "state"
  , body = Encode.string "FINISHED"
  }


scenarioConfig : Config msg -> ScenarioProgram.Config (Msg msg) msg
scenarioConfig config =
  { send = config.send
  , outlet = config.outlet
  , sendToSelf = ScenarioMsg
  , complete = sendUpdateMsg RunNextScenario
  , stop = stopSpecSuiteRun
  }


stopSpecSuiteRun : Cmd (Msg msg)
stopSpecSuiteRun =
  sendUpdateMsg <| SendMessage specFinished


sendUpdateMsg : Msg msg -> Cmd (Msg msg)
sendUpdateMsg msg =
  Task.succeed never
    |> Task.perform (always msg)


subscriptions : Config msg -> Model model msg -> Sub (Msg msg)
subscriptions config model =
  Sub.batch
  [ config.listen ReceivedMessage
  , ScenarioProgram.subscriptions model.scenarioModel
      |> Sub.map ScenarioMsg
  ]
  

init : Config msg -> List (Spec model msg) -> Flags -> Maybe Key -> ( Model model msg, Cmd (Msg msg) )
init config specs flags maybeKey =
  ( { scenarios = gatherScenarios flags.tags specs
    , scenarioModel = ScenarioProgram.init
    , key = maybeKey
    }
  , Cmd.none
  )


program : Config msg -> List (Spec model msg) -> Program Flags (Model model msg) (Msg msg)
program config specs =
  Platform.worker
    { init = \flags -> init config specs flags Nothing
    , update = update config
    , subscriptions = subscriptions config
    }


browserProgram : Config msg -> List (Spec model msg) -> Program Flags (Model model msg) (Msg msg)
browserProgram config specs =
  Browser.application
    { init = \flags _ key -> init config specs flags (Just key)
    , view = view
    , update = update config
    , subscriptions = subscriptions config
    , onUrlRequest = onUrlRequest
    , onUrlChange = onUrlChange
    }


gatherScenarios : List String -> List (Spec model msg) -> List (Scenario model msg)
gatherScenarios tags specs =
  List.map (\(Spec scenarios) -> 
    if List.isEmpty tags then
      scenarios
    else
      List.filter (withTags tags) scenarios
  ) specs
    |> List.concat


withTags : List String -> Scenario model msg -> Bool
withTags tags scenario =
  case tags of
    [] ->
      False
    tag :: remaining ->
      if List.member tag scenario.tags then
        True
      else
        withTags remaining scenario


onUrlRequest : UrlRequest -> (Msg msg)
onUrlRequest =
  ScenarioMsg << ScenarioProgram.OnUrlRequest


onUrlChange : Url -> (Msg msg)
onUrlChange =
  ScenarioMsg << ScenarioProgram.OnUrlChange
