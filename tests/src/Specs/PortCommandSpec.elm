port module Specs.PortCommandSpec exposing (..)

import Spec exposing (Spec)
import Spec.Subject as Subject
import Spec.Port as Port
import Observer
import Runner
import Task
import Json.Decode as Json


witnessPortCommandFromInitSpec : Spec Model Msg
witnessPortCommandFromInitSpec =
  Spec.given (
    Subject.worker (\_ -> ({count = 0}, sendTestMessageOut "From init!")) testUpdate
      |> Subject.withSubscriptions testSubscriptions
      |> Port.observe "sendTestMessageOut"
  )
  |> Spec.it "sends the expected message" (
    Port.expect "sendTestMessageOut" Json.string <|
        \message ->
          Observer.isEqual message "From init!"
  )


testUpdate : Msg -> Model -> ( Model, Cmd Msg )
testUpdate msg model =
  case msg of
    ReceivedString str ->
      ( model, sendTestMessageOut <| "My Port Message: " ++ str )


selectSpec : String -> Spec Model Msg
selectSpec name =
  witnessPortCommandFromInitSpec


type Msg
  = ReceivedString String


type alias Model =
  { count: Int
  }


port listenForMessage : (String -> msg) -> Sub msg
port sendTestMessageOut : String -> Cmd msg


testSubscriptions : Model -> Sub Msg
testSubscriptions model =
  listenForMessage ReceivedString


main =
  Runner.program selectSpec