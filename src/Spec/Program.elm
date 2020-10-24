module Spec.Program exposing
  ( Msg, Model, Flags
  , init, view, update, subscriptions
  , onUrlChange, onUrlRequest
  )

import Spec.Scenario.Program as ScenarioProgram
import Spec.Scenario.State as ScenarioProgram
import Spec.Scenario.Internal as Internal
import Spec.Message as Message exposing (Message)
import Spec.Helpers exposing (mapDocument)
import Spec.Report as Report
import Browser.Navigation exposing (Key)
import Browser exposing (UrlRequest, Document)
import Json.Decode as Json
import Json.Encode as Encode
import Task
import Url exposing (Url)


type alias Flags =
  { version: Int
  , segment: Int
  , segmentCount: Int
  }


type alias Config msg =
  { send: Message -> Cmd (Msg msg)
  , listen: (Message -> Msg msg) -> Sub (Msg msg)
  }


type Msg msg
  = ScenarioMsg (ScenarioProgram.Msg msg)
  | SendMessage Message
  | RunNextScenario
  | ReceivedMessage Message


type alias Segment =
  { id: Int
  , total: Int
  }


type alias Model model msg =
  { scenarios: List (Internal.Scenario model msg)
  , scenarioModel: ScenarioProgram.Model (Msg msg) msg
  , key: Maybe Key
  , tags: List String
  , segment: Segment
  }


init : (() -> List (Internal.Spec model msg)) -> Int -> Config msg -> Flags -> Maybe Key -> ( Model model msg, Cmd (Msg msg) )
init specProvider requiredElmSpecCoreVersion config flags maybeKey =
  if requiredElmSpecCoreVersion == flags.version then
    ( { scenarios = specProvider () |> gatherScenarios
      , scenarioModel = ScenarioProgram.init
      , key = maybeKey
      , tags = []
      , segment = { id = flags.segment, total = flags.segmentCount }
      }
    , Cmd.none
    )
  else
    ( { scenarios = []
      , scenarioModel = ScenarioProgram.init
      , key = maybeKey
      , tags = []
      , segment = { id = 0, total = 1 }
      }
    , versionMismatchErrorMessage requiredElmSpecCoreVersion flags.version
        |> config.send
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
          if isInSegment model.segment <| List.length remaining then
            if shouldRunScenario model.tags next then
              ScenarioProgram.run (scenarioActions config) model.key next
                |> Tuple.mapFirst (\updated -> { model | scenarioModel = updated, scenarios = remaining })
            else
              ScenarioProgram.skip (scenarioActions config) next
                |> Tuple.mapFirst (\updated -> { model | scenarioModel = updated, scenarios = remaining })
          else
            update config msg { model | scenarios = remaining }
    ScenarioMsg scenarioMsg ->
      ScenarioProgram.update (scenarioActions config) scenarioMsg model.scenarioModel
        |> Tuple.mapFirst (\updated -> { model | scenarioModel = updated })
    SendMessage message ->
      ( model, config.send message )
    ReceivedMessage message ->
      if Message.belongsTo "_spec" message then
        case message.name of
          "start" ->
            startSuite message model
          _ ->
            haltSuite config model
      else
        update config (ScenarioMsg <| ScenarioProgram.receivedMessage message) model


haltSuite : Config msg -> Model model msg -> ( Model model msg, Cmd (Msg msg) )
haltSuite config model =
  update config (ScenarioMsg <| ScenarioProgram.halt) model
    |> Tuple.mapSecond (\_ -> stopSpecSuiteRun)


startSuite : Message -> Model model msg -> ( Model model msg, Cmd (Msg msg) )
startSuite message model =
  case Message.decode tagsDecoder message of
    Ok tags ->
      ( { model | tags = tags }, sendUpdateMsg RunNextScenario )
    Err _ ->
      ( model, sendUpdateMsg RunNextScenario )


isInSegment : Segment -> Int -> Bool
isInSegment segment scenarioIndex =
  modBy segment.total scenarioIndex == segment.id


shouldRunScenario : List String -> Internal.Scenario model msg -> Bool
shouldRunScenario tags scenario =
  if List.isEmpty tags then
    List.isEmpty scenario.tags
  else
    not <| List.isEmpty scenario.tags


tagsDecoder : Json.Decoder (List String)
tagsDecoder =
  Json.field "tags" <| Json.list Json.string


specComplete : Message
specComplete =
  Message.for "_spec" "state"
    |> Message.withBody (Encode.string "COMPLETE")


specFinished : Message
specFinished =
  Message.for "_spec" "state"
    |> Message.withBody (Encode.string "FINISHED")


scenarioActions : Config msg -> ScenarioProgram.Actions (Msg msg) msg
scenarioActions config =
  { send = config.send
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


gatherScenarios : List (Internal.Spec model msg) -> List (Internal.Scenario model msg)
gatherScenarios specs =
  List.map (\(Internal.Spec scenarios) -> scenarios) specs
    |> List.concat


versionMismatchErrorMessage : Int -> Int -> Message
versionMismatchErrorMessage elmSpecCoreRequiredVersion elmSpecCoreActualVersion =
  Message.for "_spec" "error"
    |> Message.withBody (
      Report.encode <| Report.batch
        [ Report.fact "elm-spec requires elm-spec-core at version" <| String.fromInt elmSpecCoreRequiredVersion ++ ".x"
        , Report.fact "but your elm-spec-core version is" <| String.fromInt elmSpecCoreActualVersion ++ ".x"
        , Report.note "Check your JavaScript runner and upgrade to make the versions match."
        ]
    )
