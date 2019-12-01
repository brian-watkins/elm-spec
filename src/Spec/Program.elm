module Spec.Program exposing
  ( Msg, Model
  , init, view, update, subscriptions
  , onUrlChange, onUrlRequest
  )

import Spec.Scenario.Program as ScenarioProgram
import Spec.Scenario.State as ScenarioProgram
import Spec.Scenario.Internal as Internal
import Spec.Message as Message exposing (Message)
import Spec.Helpers exposing (mapDocument)
import Browser.Navigation exposing (Key)
import Browser exposing (UrlRequest, Document)
import Json.Decode as Json
import Json.Encode as Encode
import Task
import Url exposing (Url)


type alias Flags =
  { tags: List String
  }


type alias Config msg =
  { send: Message -> Cmd (Msg msg)
  , outlet: Message -> Cmd msg
  , listen: (Message -> Msg msg) -> Sub (Msg msg)
  }


type Msg msg
  = ScenarioMsg (ScenarioProgram.Msg msg)
  | SendMessage Message
  | RunNextScenario
  | ReceivedMessage Message


type alias Model model msg =
  { scenarios: List (Internal.Scenario model msg)
  , scenarioModel: ScenarioProgram.Model model msg
  , key: Maybe Key
  }


init : (() -> List (Internal.Spec model msg)) -> Config msg -> Flags -> Maybe Key -> ( Model model msg, Cmd (Msg msg) )
init specProvider config flags maybeKey =
  ( { scenarios =
        specProvider ()
          |> gatherScenarios flags.tags
    , scenarioModel = ScenarioProgram.init
    , key = maybeKey
    }
  , Cmd.none
  )


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
        next :: remaining ->
          ScenarioProgram.start (scenarioConfig config) model.key next
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
  Message.for "_spec" "state"
    |> Message.withBody (Encode.string "COMPLETE")


specFinished : Message
specFinished =
  Message.for "_spec" "state"
    |> Message.withBody (Encode.string "FINISHED")


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
  

onUrlRequest : UrlRequest -> (Msg msg)
onUrlRequest =
  ScenarioMsg << ScenarioProgram.OnUrlRequest


onUrlChange : Url -> (Msg msg)
onUrlChange =
  ScenarioMsg << ScenarioProgram.OnUrlChange


gatherScenarios : List String -> List (Internal.Spec model msg) -> List (Internal.Scenario model msg)
gatherScenarios tags specs =
  List.map (\(Internal.Spec scenarios) -> 
    if List.isEmpty tags then
      scenarios
    else
      List.filter (withTags tags) scenarios
  ) specs
    |> List.concat


withTags : List String -> Internal.Scenario model msg -> Bool
withTags tags scenarioData =
  case tags of
    [] ->
      False
    tag :: remaining ->
      if List.member tag scenarioData.tags then
        True
      else
        withTags remaining scenarioData

