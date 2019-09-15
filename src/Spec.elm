module Spec exposing
  ( Spec
  , describe
  , Model, Msg, Config
  , update, view, init, subscriptions
  , program
  , browserProgram
  )

import Spec.Message as Message exposing (Message)
import Spec.Scenario as Scenario exposing (Scenario)
import Spec.Scenario.Message as Message
import Spec.Scenario.Program as ScenarioProgram
import Spec.Scenario.State as ScenarioProgram
import Spec.Observation.Message as Message
import Task
import Html exposing (Html)
import Browser
import Json.Encode as Encode


type Spec model msg =
  Spec
    (List (Scenario model msg))


describe : String -> List (Scenario model msg) -> Spec model msg
describe description scenarios =
  scenarios
    |> List.map (Scenario.addCondition <| formatSpecDescription description)
    |> Spec


formatSpecDescription : String -> String
formatSpecDescription description =
  "Describing: " ++ description


---- Program


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
  { scenarios: List (Scenario model msg)
  , scenarioModel: ScenarioProgram.Model model msg
  }


view : Model model msg -> Html (Msg msg)
view model =
  ScenarioProgram.view model.scenarioModel
    |> Html.map ScenarioMsg


update : Config msg -> Msg msg -> Model model msg -> ( Model model msg, Cmd (Msg msg) )
update config msg model =
  case msg of
    RunNextScenario ->
      case model.scenarios of
        [] ->
          ( model, config.send specComplete )
        scenario :: remaining ->
          ( { model | scenarioModel = ScenarioProgram.with scenario, scenarios = remaining }
          , Cmd.map ScenarioMsg ScenarioProgram.start
          )
    ScenarioMsg scenarioMsg ->
      ScenarioProgram.update (scenarioConfig config) scenarioMsg model.scenarioModel
        |> Tuple.mapFirst (\updated -> { model | scenarioModel = updated })
    SendMessage message ->
      ( model, config.send message )
    ReceivedMessage message ->
      if message.home == "_spec" then
        update config RunNextScenario model
      else
        update config (ScenarioMsg <| ScenarioProgram.receivedMessage message) model


specComplete : Message
specComplete =
  { home = "_spec"
  , name = "state"
  , body = Encode.string "SPEC_COMPLETE"
  }


scenarioConfig : Config msg -> ScenarioProgram.Config (Msg msg) msg
scenarioConfig config =
  { send = config.send
  , outlet = config.outlet
  , sendToSelf = ScenarioMsg
  , complete = Task.succeed never |> Task.perform (always RunNextScenario)
  , stop = config.send specComplete
  }


subscriptions : Config msg -> Model model msg -> Sub (Msg msg)
subscriptions config model =
  Sub.batch
  [ config.listen ReceivedMessage
  , ScenarioProgram.subscriptions model.scenarioModel
      |> Sub.map ScenarioMsg
  ]
  

init : Config msg -> List (Spec model msg) -> () -> ( Model model msg, Cmd (Msg msg) )
init config specs _ =
  ( { scenarios =
        List.map (\(Spec scenarios) -> scenarios) specs
          |> List.concat
    , scenarioModel = ScenarioProgram.init
    }
  , Cmd.none
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
