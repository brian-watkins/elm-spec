module Spec.Port exposing
  ( record
  , send
  , observe
  )

{-| Functions for working with ports during a spec.

Suppose your app sends a port command when a button is clicked,
and then displays a message received over a port subscription. You
could write a scenario like so:

    Spec.describe "command ports and subscription ports"
    [ Spec.scenario "send and receive" (
        Spec.given (
          Spec.Setup.withInit (App.init testFlags)
            |> Spec.Setup.withUpdate App.update
            |> Spec.Setup.withView App.view
            |> Spec.Setup.withSubscriptions App.subscriptions
            |> Spec.Port.record "my-command-port"
        )
        |> Spec.when "a message is sent out"
          [ Spec.Markup.target << by [ tag "button" ]
          , Spec.Markup.Event.click
          ]
        |> Spec.when "a response is received"
          [ Spec.Port.send "my-subscription-port" <|
              Json.Encode.object
                [ ("message", Encode.string "Have fun!")
                ]
          ]
        |> Spec.observeThat
          [ Spec.it "sent one message over the port" (
              Spec.Port.observe "my-command-port" someDecoder
                |> Spec.expect (Spec.isListWithLength 1)
            )
          , Spec.it "shows the message received" (
              Spec.Markup.observeElement
                |> Spec.Markup.query << by [ id "message" ]
                |> Spec.expect (Spec.Markup.hasText "Have fun!")
            )
          ]
      )
    ]

# Observe Command Ports
@docs record, observe

# Simulate Subscription Ports
@docs send

-}

import Spec.Setup as Setup exposing (Setup)
import Spec.Setup.Internal as Setup
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


{-| Setup the scenario to record messages sent via a command port.

Note: If a port command is sent at any time during the scenario script, you must
use `record` to setup the scenario to record messages on that port.
Otherwise, the scenario may time out.

-}
record : String -> Setup model msg -> Setup model msg
record portName =
  observePortCommand portName
    |> Setup.configure


{-| A step that sends a message to a port subscription.

Provide the name of the port and an encoded JSON value that should be sent from the JavaScript side.

For example, if you have a port like so:

    port listenForStuff : (String -> msg) -> Sub msg

Then you could send a message on this port like so:

    Spec.when "a message is sent to the subscription"
    [ Spec.Port.send "listenForStuff" <| Encode.string "Some words"
    ]

-}
send : String -> Encode.Value -> Step.Context model -> Step.Command msg
send name value _ =
  Command.sendMessage <| sendSubscription name value


type alias PortRecord =
  { name: String
  , value: Json.Value
  }


{-| Observe messages sent out via a command port.

Provide the name of the port (the function name) and a decoder that can decode
messages sent out over the port.

-}
observe : String -> Json.Decoder a -> Observer model (List a)
observe name decoder =
  Observer.observeEffects (\effects ->
    recordsForPort name effects
      |> recordedValues decoder
  )
  |> Observer.mapRejection (\report ->
    Report.batch
    [ Report.fact "Claim rejected for port" name
    , report
    ]
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