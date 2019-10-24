module Spec.Observer exposing
  ( Observer
  , Expectation
  , observeModel
  , observeEffects
  , inquire
  , inquireForResult
  , mapRejection
  )

import Spec.Message as Message exposing (Message)
import Spec.Claim as Claim exposing (Claim)
import Spec.Observation.Expectation as Expectation
import Spec.Observation.Report exposing (Report)


type alias Expectation model =
  Expectation.Expectation model


type alias Observer model a =
  Claim a -> Expectation model


observeModel : (model -> a) -> Observer model a
observeModel mapper observer =
  Expectation.Expectation <| \context ->
    mapper context.model
      |> observer
      |> Expectation.Complete


observeEffects : (List Message -> a) -> Observer model a
observeEffects mapper observer =
  Expectation.Expectation <| \context ->
    mapper context.effects
      |> observer
      |> Expectation.Complete


inquire : Message -> (Message -> a) -> Observer model a
inquire message mapper =
  inquireForResult message <| \response ->
    Ok <| mapper response


inquireForResult : Message -> (Message -> Result Report a) -> Observer model a
inquireForResult message resultMapper claim =
  Expectation.Expectation <| \context ->
    Expectation.Inquire message <|
      \inquiryResult ->
        case resultMapper inquiryResult of
          Ok value ->
            claim value
              |> Expectation.Complete
          Err report ->
            Claim.Reject report
              |> Expectation.Complete


mapRejection : (Report -> Report) -> Observer model a -> Observer model a
mapRejection mapper observer =
  \claim ->
    observer <| \actual ->
      case claim actual of
        Claim.Accept ->
          Claim.Accept
        Claim.Reject report ->
          Claim.Reject <| mapper report
