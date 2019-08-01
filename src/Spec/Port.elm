module Spec.Port exposing
  ( observe
  , send
  , expect
  )

import Spec exposing (Spec)
import Spec.Subject as Subject exposing (Subject)
import Observer exposing (Observer)
import Spec.Message exposing (Message)
import Json.Encode as Encode
import Json.Decode as Json


sendSubscription : String -> Encode.Value -> Message
sendSubscription name value =
  { home = "spec-send"
  , body = Encode.object [ ("sub", Encode.string name), ("value", value) ]
  }


observePortCommand : String -> Message
observePortCommand name =
  { home = "spec-receive"
  , body = Encode.object [ ("cmd", Encode.string name) ]
  }


observe : String -> Subject model msg -> Subject model msg
observe portName =
  observePortCommand portName
    |> Spec.sendMessage
    |> Subject.configure


send : String -> Encode.Value -> Spec model msg -> Spec model msg
send name value =
  Spec.doStep <| \_ ->
    sendSubscription name value
      |> Spec.sendMessage


expect : String -> Json.Decoder a -> Observer a -> Observer (Subject model msg)
expect name decoder observer subject =
  Subject.effects subject
    |> List.head
    |> Maybe.map (\message ->
      Json.decodeValue decoder message.body
        |> Result.map observer
        |> Result.withDefault (Observer.Reject "Unable to parse!")
    )
    |> Maybe.withDefault (Observer.Reject "NOT DONE YET")
