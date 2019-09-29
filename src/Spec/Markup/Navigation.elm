module Spec.Markup.Navigation exposing
  ( selectLocation
  , expectReload
  )

import Spec.Observation as Observation exposing (Selection, Expectation)
import Spec.Observer as Observer
import Spec.Observation.Report as Report
import Spec.Message as Message exposing (Message)
import Json.Encode as Encode
import Json.Decode as Json


selectLocation : Selection model String
selectLocation =
  Observation.inquire selectLocationMessage
    |> Observation.mapSelection (Message.decode Json.string)
    |> Observation.mapSelection (Maybe.withDefault "FAILED")


selectLocationMessage : Message
selectLocationMessage =
  { home = "_html"
  , name = "navigation"
  , body = Encode.string "select-location"
  }


expectReload : Expectation model
expectReload =
  Observation.selectEffects
    |> Observation.mapSelection (List.filter (Message.is "_navigation" "reload"))
    |> Observation.expect (\messages ->
      if List.length messages > 0 then
        Observer.Accept
      else
        Observer.Reject <| Report.note "Expected Browser.Navigation.reload or Browser.Navigation.reloadAndSkipCache but neither command was executed"
    )