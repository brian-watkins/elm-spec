module Spec.Markup.Navigation exposing
  ( observeLocation
  , expectReload
  )

{-| Functions for observing navigation changes.

@docs observeLocation, expectReload

-}

import Spec
import Spec.Observer as Observer exposing (Observer, Expectation)
import Spec.Observer.Internal as Observer
import Spec.Claim as Claim
import Spec.Report as Report
import Spec.Message as Message exposing (Message)
import Json.Encode as Encode
import Json.Decode as Json


{-| Observe the current location of the document.

    Spec.it "has the correct location" (
      observeLocation
        |> Spec.expect (
           Spec.Claim.isEqual Debug.toString
             "http://fake-server.com/something-fun"
        )
    )

This is useful to observe that `Browswer.Navigation.load`,
`Browser.Navigation.pushUrl`, or `Browser.Navigation.replaceUrl` was
executed with the value you expect.

Note that you can use `Spec.Setup.withLocation` to set the base location
of the document at the start of the scenario.

-}
observeLocation : Observer model String
observeLocation =
  Observer.inquire observeLocationMessage <| \message ->
    Message.decode Json.string message
      |> Result.withDefault "FAILED"


observeLocationMessage : Message
observeLocationMessage =
  Message.for "_html" "navigation"
    |> Message.withBody (
      Encode.string "select-location"
    )


{-| Expect that a `Browser.Navigation.reload` or `Browser.Navigation.reloadAndSkipCache`
command was executed.
-}
expectReload : Expectation model
expectReload =
  Observer.observeEffects (List.filter (Message.is "_navigation" "reload"))
    |> Spec.expect (\messages ->
      if List.length messages > 0 then
        Claim.Accept
      else
        Claim.Reject <| Report.note "Expected Browser.Navigation.reload or Browser.Navigation.reloadAndSkipCache but neither command was executed"
    )