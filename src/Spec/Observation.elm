module Spec.Observation exposing
  ( Selection
  , selectModel
  , selectEffects
  , inquire
  , inquireForResult
  )

import Spec.Message as Message exposing (Message)
import Spec.Claim as Claim exposing (Claim)
import Spec.Observation.Expectation as Expectation
import Spec.Observation.Report exposing (Report)


type alias Selection model a =
  Claim a -> Expectation.Expectation model


selectModel : (model -> a) -> Selection model a
selectModel mapper observer =
  Expectation.Expectation <| \context ->
    mapper context.model
      |> observer
      |> Expectation.Complete


selectEffects : (List Message -> a) -> Selection model a
selectEffects mapper observer =
  Expectation.Expectation <| \context ->
    mapper context.effects
      |> observer
      |> Expectation.Complete


inquire : Message -> (Message -> a) -> Selection model a
inquire message mapper =
  inquireForResult message <| \response ->
    Ok <| mapper response


inquireForResult : Message -> (Message -> Result Report a) -> Selection model a
inquireForResult message resultMapper observer =
  Expectation.Expectation <| \context ->
    Expectation.Inquire message <|
      \inquiryResult ->
        case resultMapper inquiryResult of
          Ok value ->
            observer value
              |> Expectation.Complete
          Err report ->
            Claim.Reject report
              |> Expectation.Complete
