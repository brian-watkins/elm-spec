module Spec.Port exposing
  ( record
  , send
  , observe
  )

import Spec.Setup as Setup exposing (Setup)
import Spec.Step as Step
import Spec.Step.Command as Command
import Spec.Observer as Observer exposing (Observer)
import Spec.Observer.Internal as Observer
import Spec.Claim as Claim exposing (Claim)
import Spec.Message as Message exposing (Message)
import Spec.Report as Report exposing (Report)
import Json.Encode as Encode
import Json.Decode as Json


sendSubscription : String -> Encode.Value -> Message
sendSubscription name value =
  Message.for "_port" "send"
    |> Message.withBody (
      Encode.object [ ("sub", Encode.string name), ("value", value) ]
    )


observePortCommand : String -> Message
observePortCommand name =
  Message.for "_port" "receive"
    |> Message.withBody (
      Encode.object [ ("cmd", Encode.string name) ]
    )


record : String -> Setup model msg -> Setup model msg
record portName =
  observePortCommand portName
    |> Setup.configure


send : String -> Encode.Value -> Step.Context model -> Step.Command msg
send name value _ =
  Command.sendMessage <| sendSubscription name value


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