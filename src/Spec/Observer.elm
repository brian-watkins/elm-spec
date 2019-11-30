module Spec.Observer exposing
  ( Observer
  , Expectation
  , observeModel
  , observeEffects
  , inquire
  , mapRejection
  , observeResult
  )

import Spec.Message as Message exposing (Message)
import Spec.Claim as Claim exposing (Claim)
import Spec.Observation.Expectation as Expectation
import Spec.Report exposing (Report)


type alias Expectation model =
  Expectation.Expectation model


type alias Observer model a =
  Claim a -> Expectation model


observeModel : (model -> a) -> Observer model a
observeModel mapper claim =
  Expectation.Expectation <| \context ->
    mapper context.model
      |> claim
      |> Expectation.Complete


observeEffects : (List Message -> a) -> Observer model a
observeEffects mapper claim =
  Expectation.Expectation <| \context ->
    mapper context.effects
      |> claim
      |> Expectation.Complete


inquire : Message -> (Message -> a) -> Observer model a
inquire message mapper claim =
  Expectation.Expectation <| \context ->
    Expectation.Inquire message <|
      \response ->
        mapper response
          |> claim
          |> Expectation.Complete


observeResult : Observer model (Result Report a) -> Observer model a
observeResult observer =
  \claim ->
    observer <| \actual ->
      case actual of
        Ok value ->
          claim value
        Err report ->
          Claim.Reject report


mapRejection : (Report -> Report) -> Observer model a -> Observer model a
mapRejection mapper observer =
  \claim ->
    observer <| \actual ->
      case claim actual of
        Claim.Accept ->
          Claim.Accept
        Claim.Reject report ->
          Claim.Reject <| mapper report
