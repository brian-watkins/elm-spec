module Spec.Port exposing
  ( record
  , send
  , observe
  )

import Spec.Subject as Subject exposing (SubjectGenerator)
import Spec.Step as Step
import Spec.Observer as Observer exposing (Observer)
import Spec.Claim as Claim exposing (Claim)
import Spec.Message as Message exposing (Message)
import Spec.Observation.Report as Report exposing (Report)
import Json.Encode as Encode
import Json.Decode as Json


sendSubscription : String -> Encode.Value -> Message
sendSubscription name value =
  { home = "_port"
  , name = "send"
  , body = Encode.object [ ("sub", Encode.string name), ("value", value) ]
  }


observePortCommand : String -> Message
observePortCommand name =
  { home = "_port"
  , name = "receive"
  , body = Encode.object [ ("cmd", Encode.string name) ]
  }


record : String -> SubjectGenerator model msg -> SubjectGenerator model msg
record portName =
  observePortCommand portName
    |> Subject.configure


send : String -> Encode.Value -> Step.Context model -> Step.Command msg
send name value _ =
  Step.sendMessage <| sendSubscription name value


type alias PortRecord =
  { name: String
  , value: Json.Value
  }


observe : String -> Json.Decoder a -> Observer model (List a)
observe name decoder =
  Observer.observeEffects (\effects ->
    recordsForPort name effects
      |> recordedValues decoder
  )
  |> Observer.mapRejection (
    Report.append <| Report.fact "Claim rejected for port" name
  )
  |> Observer.observeResult


recordsForPort : String -> List Message -> List PortRecord
recordsForPort name effects =
  List.filter (Message.is "_port" "received") effects
    |> List.filterMap (Message.decode recordDecoder)
    |> List.filter (\portRecord -> portRecord.name == name)


recordedValues : Json.Decoder a -> List PortRecord -> Result Report (List a)
recordedValues decoder =
  List.foldl (\portRecord ->
    Result.andThen (\values ->
      Json.decodeValue decoder portRecord.value
        |> Result.map (\value -> List.append values [ value ])
        |> Result.mapError jsonErrorToReport
    )
  ) (Ok [])


jsonErrorToReport : Json.Error -> Report
jsonErrorToReport =
  Report.fact "Unable to decode value sent through port" << Json.errorToString

recordDecoder : Json.Decoder PortRecord
recordDecoder =
  Json.map2 PortRecord
    (Json.field "name" Json.string)
    (Json.field "value" Json.value)