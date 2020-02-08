module Specs.Helpers exposing
  ( stringify
  , equals
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
