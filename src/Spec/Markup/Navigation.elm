module Spec.Markup.Navigation exposing
  ( observeLocation
  , expectReload
  )

import Spec
import Spec.Observer as Observer exposing (Observer, Expectation)
import Spec.Claim as Claim
import Spec.Report as Report
import Spec.Message as Message exposing (Message)
import Json.Encode as Encode
import Json.Decode as Json


observeLocation : Observer model String
observeLocation =
  Observer.inquire observeLocationMessage <| \message ->
    Message.decode Json.string message
      |> Maybe.withDefault "FAILED"


observeLocationMessage : Message
observeLocationMessage =
  { home = "_html"
  , name = "navigation"
  , body = Encode.string "select-location"
  }


expectReload : Expectation model
expectReload =
  Observer.observeEffects (List.filter (Message.is "_navigation" "reload"))
    |> Spec.expect (\messages ->
      if List.length messages > 0 then
        Claim.Accept
      else
        Claim.Reject <| Report.note "Expected Browser.Navigation.reload or Browser.Navigation.reloadAndSkipCache but neither command was executed"
    )