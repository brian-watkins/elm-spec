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


observe : String -> Subject model msg -> Subject model msg
observe portName =
  observePortCommand portName
    |> Subject.configure


send : String -> Encode.Value -> Subject model msg -> Message
send name value _ =
  sendSubscription name value


expect : String -> Json.Decoder a -> Observer (List a) -> Observer (Subject model msg)
expect name decoder observer subject =
  Subject.effects subject
    |> List.filter (\message -> message.home == "_port" && message.name == "received")
    |> List.filterMap (\message ->
      Json.decodeValue decoder message.body
        |> Result.toMaybe
    )
    |> observer
