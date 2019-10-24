module Spec.Port exposing
  ( record
  , send
  , observeRecordedValues
  )

import Spec.Subject as Subject exposing (SubjectGenerator)
import Spec.Step as Step
import Spec.Observer as Observer exposing (Observer)
import Spec.Claim as Claim exposing (Claim)
import Spec.Message as Message exposing (Message)
import Spec.Observation.Report as Report
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


observeRecordedValues : String -> Json.Decoder a -> Observer model (List a)
observeRecordedValues name decoder =
  Observer.observeEffects (\effects ->
    recordsForPort name effects
      |> recordedValues decoder
  )
  |> Observer.mapRejection (
    Report.append <| Report.fact "Claim rejected for port" name
  )


recordsForPort : String -> List Message -> List PortRecord
recordsForPort name effects =
  List.filter (Message.is "_port" "received") effects
    |> List.filterMap (Message.decode recordDecoder)
    |> List.filter (\portRecord -> portRecord.name == name)


recordedValues : Json.Decoder a -> List PortRecord -> List a
recordedValues decoder records =
  List.map (\portRecord -> Json.decodeValue decoder portRecord.value) records
    |> List.filterMap Result.toMaybe


recordDecoder : Json.Decoder PortRecord
recordDecoder =
  Json.map2 PortRecord
    (Json.field "name" Json.string)
    (Json.field "value" Json.value)