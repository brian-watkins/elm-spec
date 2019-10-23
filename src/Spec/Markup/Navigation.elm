module Spec.Markup.Navigation exposing
  ( selectLocation
  , expectReload
  )

import Spec.Scenario as Scenario exposing (Expectation)
import Spec.Observation as Observation exposing (Selection)
import Spec.Observer as Observer
import Spec.Observation.Report as Report
import Spec.Message as Message exposing (Message)
import Json.Encode as Encode
import Json.Decode as Json


selectLocation : Selection model String
selectLocation =
  Observation.inquire selectLocationMessage <| \message ->
    Message.decode Json.string message
      |> Maybe.withDefault "FAILED"


selectLocationMessage : Message
selectLocationMessage =
  { home = "_html"
  , name = "navigation"
  , body = Encode.string "select-location"
  }


expectReload : Expectation model
expectReload =
  Observation.selectEffects (List.filter (Message.is "_navigation" "reload"))
    |> Scenario.expect (\messages ->
      if List.length messages > 0 then
        Observer.Accept
      else
        Observer.Reject <| Report.note "Expected Browser.Navigation.reload or Browser.Navigation.reloadAndSkipCache but neither command was executed"
    )