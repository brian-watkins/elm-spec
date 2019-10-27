module Specs.Helpers exposing
  ( stringify
  , equals
  )

import Spec.Claim as Claim exposing (Claim)


equals : a -> Claim a
equals =
  Claim.isEqual stringify

stringify : a -> String
stringify =
  Debug.toString