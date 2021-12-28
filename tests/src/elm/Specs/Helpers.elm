module Specs.Helpers exposing
  ( stringify
  , equals
  , isListWhereSomeItem
  , itShouldHaveFailedAlready
  )

import Spec exposing (it, expect)
import Spec.Claim as Claim exposing (Claim)
import Spec.Observer as Observer
import Spec.Report as Report


equals : a -> Claim a
equals =
  Claim.isEqual stringify

stringify : a -> String
stringify =
  Debug.toString


itShouldHaveFailedAlready =
  it "should have failed already" (
    Observer.observeModel (\_ -> ())
      |> expect (\_ -> Claim.Reject <| Report.note "Should have failed already!")
  )


isListWhereSomeItem : Claim a -> Claim (List a)
isListWhereSomeItem claim =
  \actual ->
    List.map claim actual
      |> List.filter (\verdict -> verdict == Claim.Accept)
      |> List.length
      |> \acceptedClaims ->
        if acceptedClaims > 0 then
          Claim.Accept
        else
          Claim.Reject <| Report.batch
            [ Report.fact "No item in the list" <| stringify actual
            , Report.note "matched the expected claim"
            ]