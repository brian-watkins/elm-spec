port module Specs.PortCommandSpec exposing (..)

import Spec exposing (..)
import Spec.Setup as Setup
import Spec.Port as Port
import Spec.Claim as Claim
import Spec.Observer as Observer
import Spec.Command as Command
import Specs.Helpers exposing (..)
import Runner
import Json.Decode as Json
import Json.Encode as Encode

witnessPortCommandFromInitSpec : Spec Model Msg
witnessPortCommandFromInitSpec =
  Spec.describe "a worker with a port"
  [ scenario "commands sent via a port are observed" (
      given (
        Setup.init ( testModel, sendTestMessageOut "From init!")
          |> Setup.withUpdate testUpdate
      )
      |> it "sends the expected message" (
        Port.observe "sendTestMessageOut" Json.string
          |> expect (equals [ "From init!" ])
      )
    )
  , scenario "multiple port messages are observed in the right order" (
      given (
        Setup.initWithModel testModel
          |> Setup.withUpdate testUpdate
      )
      |> when "port messages are sent"
        [ Command.send <| sendTestMessageOut "From step 1"
        , Command.send <| sendTestMessageOut "From step 2"
        , Command.send <| sendTestMessageOut "From step 3"
        ]
      |> it "records the messages in the proper order" (
        Port.observe "sendTestMessageOut" Json.string
          |> expect (equals
            [ "From step 1"
            , "From step 2"
            , "From step 3"
            ]
          )
      )
    )
  , scenario "observing the same port in another scenario" (
      given (
        Setup.init ( testModel, sendTestMessageOut "From init in another scenario!")
          |> Setup.withUpdate testUpdate
      )
      |> it "resets the subscription between scenarios so only one request is observed" (
        Port.observe "sendTestMessageOut" Json.string
          |> expect (equals [ "From init in another scenario!" ])
      )
    )
  , scenario "observing a port that is not being recorded" (
      given (
        Setup.init ( testModel, sendTestMessageOut "Some message!")
          |> Setup.withUpdate testUpdate
      )
      |> it "fails" (
        Port.observe "some-other-port" Json.string
          |> expect (equals [ "Unknown!" ])
      )
    )
  , scenario "decoding a port value with the wrong decoder" (
      given (
        Setup.init ( testModel, sendTestMessageOut "From init!")
          |> Setup.withUpdate testUpdate
      )
      |> it "fails" (
        Port.observe "sendTestMessageOut" Json.int
          |> expect (equals [ 17 ])
      )
    )
  ]


witnessMultiplePortCommandsFromInitSpec : Spec Model Msg
witnessMultiplePortCommandsFromInitSpec =
  Spec.describe "a worker with a port"
  [ scenario "multiple port commands are witnessed" (
      given (
        Setup.init
          ( testModel
          , Cmd.batch [ sendTestMessageOut "One", sendTestMessageOut "Two", sendTestMessageOut "Three" ]
          )
        |> Setup.withUpdate testUpdate
      )
      |> it "records all the messages sent" (
        Port.observe "sendTestMessageOut" Json.string
          |> expect (Claim.satisfying
            [ Claim.isTrue << List.member "One"
            , Claim.isTrue << List.member "Two"
            , Claim.isTrue << List.member "Three"
            ]
          )
      )
    )
  ]


respondToPortMessages : Spec Model Msg
respondToPortMessages =
  Spec.describe "responding to port messages in a step"
  [ scenario "no port command messages have been sent" (
      given (
        Setup.initWithModel testModel
          |> Setup.withUpdate testUpdate
          |> Setup.withSubscriptions testSubscriptions
      )
      |> when "a response is sent"
        [ Port.respond "sendTestMessageOut" Json.string <| \message ->
            Port.send "receiveTestMessage" (Encode.string message)
        ]
      |> itShouldHaveFailedAlready
    )
  , scenario "several port messages have been sent" (
      given (
        Setup.initWithModel testModel
          |> Setup.withUpdate testUpdate
          |> Setup.withSubscriptions testSubscriptions
      )
      |> when "port messages are sent"
        [ Command.send <| sendTestMessageOut "One"
        , Command.send <| sendTestMessageOut "Two"
        , Command.send <| sendTestMessageOut "Three"
        ]
      |> when "a response is sent for each message"
        [ Port.respond "sendTestMessageOut" Json.string <| \message ->
            Encode.string ("Response: " ++ message)
              |> Port.send "receiveTestMessage"
        ]
      |> it "receives the response to the last message" (
        Observer.observeModel .messages
          |> expect (Claim.satisfying
            [ Claim.isListWithLength 3
            , isListWhereSomeItem <| equals "Response: Three"
            , isListWhereSomeItem <| equals "Response: Two"
            , isListWhereSomeItem <| equals "Response: One" 
            ])
      )
    )
  , scenario "different responses" (
      given (
        Setup.initWithModel testModel
          |> Setup.withUpdate testUpdate
          |> Setup.withSubscriptions testSubscriptions
      )
      |> when "port messages are sent"
        [ Command.send <| sendTestMessageOut "One"
        , Command.send <| sendTestMessageOut "Two"
        , Command.send <| sendTestMessageOut "Three"
        ]
      |> when "a response is sent for each message"
        [ Port.respond "sendTestMessageOut" Json.string <| \message ->
            Encode.string ("Response: " ++ message)
              |> Port.send "receiveTestMessage"
        ]
      |> when "more port messages are sent"
        [ Command.send <| sendTestMessageOut "Four"
        , Command.send <| sendTestMessageOut "Five"
        ]
      |> when "a different response is sent for each new message"
        [ Port.respond "sendTestMessageOut" Json.string <| \message ->
            Encode.string ("Response Round 2: " ++ message)
              |> Port.send "receiveTestMessage"
        ]
      |> it "receives the response to the last message" (
        Observer.observeModel .messages
          |> expect (Claim.satisfying
            [ Claim.isListWithLength 5
            , isListWhereSomeItem <| equals "Response Round 2: Five"
            , isListWhereSomeItem <| equals "Response Round 2: Four"
            , isListWhereSomeItem <| equals "Response: Three"
            , isListWhereSomeItem <| equals "Response: Two"
            , isListWhereSomeItem <| equals "Response: One" 
            ])
      )
    )
  , scenario "decoding the port messages results in an error" (
      given (
        Setup.initWithModel testModel
          |> Setup.withUpdate testUpdate
          |> Setup.withSubscriptions testSubscriptions
      )
      |> when "port messages are sent"
        [ Command.send <| sendTestMessageOut "One"
        ]
      |> when "port messages are observed with the wrong decoder"
        [ Port.respond "sendTestMessageOut" Json.int <| \message ->
            Encode.int message
              |> Port.send "receiveTestMessage"
        ]
      |> itShouldHaveFailedAlready
    )
  ]


type Msg
  = MessageReceived String


type alias Model =
  { count: Int
  , messages: List String
  }


testModel : Model
testModel =
  { count = 0
  , messages = []
  }


testUpdate : Msg -> Model -> ( Model, Cmd Msg )
testUpdate msg model =
  case msg of
    MessageReceived message ->
      ( { model | messages = message :: model.messages }, Cmd.none )


testSubscriptions : Model -> Sub Msg
testSubscriptions _ =
  receiveTestMessage MessageReceived


port sendTestMessageOut : String -> Cmd msg
port receiveTestMessage : (String -> msg) -> Sub msg


selectSpec : String -> Maybe (Spec Model Msg)
selectSpec name =
  case name of
    "one" -> Just witnessPortCommandFromInitSpec
    "many" -> Just witnessMultiplePortCommandsFromInitSpec
    "observe" -> Just respondToPortMessages
    _ -> Nothing


main =
  Runner.program selectSpec