module Spec.Observer exposing
  ( Observer
  , Expectation
  , observeModel
  , mapRejection
  , observeResult
  )

{-| An observer evaluates a claim with respect to some part of the world.

This module contains functions for working with observers at a high level.

Check out `Spec.Markup`, `Spec.Http`, `Spec.Port`, and `Spec.Witness` for
more observers.

# Build Observers
@docs Expectation, Observer, observeModel

# Work with Observers
@docs observeResult, mapRejection

-}

import Spec.Observer.Internal as Internal
import Spec.Message as Message exposing (Message)
import Spec.Claim as Claim exposing (Claim)
import Spec.Observer.Expectation as Expectation
import Spec.Report exposing (Report)


{-| Represents what should be the case about some part of the world.

Expectations are checked at the end of the scenario, after all steps of the
script have been performed.
-}
type alias Expectation model =
  Expectation.Expectation model


{-| An `Observer` determines whether to accept or reject a claim with
respect to some particular part of the world. It is a function from a
claim to an `Expectation` that will be evaluted at the end of the scenario.
-}
type alias Observer model a =
  Internal.Observer model a


{-| Observe some aspect of the model of the program whose behavior is being described in this scenario.

For example, if the program model looks like `{ score: 27 }`, then you could observe the
score like so:

    Spec.it "has the correct score" (
      observeModel .score
        |> Spec.expect 
          (Spec.Claim.isEqual Debug.toString 27)
    )

Check out `Spec.Markup`, `Spec.Http`, `Spec.Port`, and `Spec.Witness` for
observers that evaluate claims with respect to the world outside the program.

-}
observeModel : (model -> a) -> Observer model a
observeModel mapper =
  Internal.for <| \claim ->
    Expectation.Expectation <| \context ->
      mapper context.model
        |> claim
        |> Expectation.Complete


{-| Create a new `Observer` that will evaluate a `Claim` with respect to
the successful `Result` observed by the given `Observer`. If the `Result`
fails then the `Claim` will be rejected.
-}
observeResult : Observer model (Result Report a) -> Observer model a
observeResult =
  Internal.andThenClaim <| \claim ->
    \actual ->
      case actual of
        Ok value ->
          claim value
        Err report ->
          Claim.Reject report


{-| Create a new `Observer` that will map the `Report` created if the `Claim` is rejected.
-}
mapRejection : (Report -> Report) -> Observer model a -> Observer model a
mapRejection mapper =
  Internal.andThenClaim <| \claim ->
    \actual ->
      case claim actual of
        Claim.Accept ->
          Claim.Accept
        Claim.Reject report ->
          Claim.Reject <| mapper report
