module Spec.Observation exposing
  ( Selection
  , selectModel
  , selectEffects
  , inquire
  , inquireForResult
  , mapSelection
  , Expectation
  , expect
  )

import Spec.Message as Message exposing (Message)
import Spec.Observer as Observer exposing (Observer, Verdict)
import Spec.Observation.Expectation as Expectation
import Spec.Observation.Report exposing (Report)


type Selection model a
  = Model (model -> a)
  | Effects (List Message -> a)
  | Inquiry Message (Message -> Result Report a)


type alias Expectation model =
  Expectation.Expectation model


selectModel : Selection model model
selectModel =
  Model identity


selectEffects : Selection model (List Message)
selectEffects =
  Effects identity


inquire : Message -> Selection model Message
inquire message =
  Inquiry message Ok


inquireForResult : Message -> (Message -> Result Report a) -> Selection model a
inquireForResult message resultMapper =
  Inquiry message resultMapper


mapSelection : (a -> b) -> Selection model a -> Selection model b
mapSelection mapper selection =
  case selection of
    Model generator ->
      Model (generator >> mapper)
    Effects generator ->
      Effects (generator >> mapper)
    Inquiry message generator ->
      Inquiry message (\m -> generator m |> Result.map mapper) -- generator >> mapper)


expect : Observer a -> Selection model a -> Expectation model
expect observer selection =
  Expectation.Expectation <|
    \context ->
      case selection of
        Model mapper ->
          mapper context.model
            |> observer
            |> Expectation.Complete
        Effects mapper ->
          mapper context.effects
            |> observer
            |> Expectation.Complete
        Inquiry message mapper ->
          Expectation.Inquire message <|
            \inquiryResult ->
              case mapper inquiryResult of
                Ok value ->
                  observer value
                    |> Expectation.Complete
                Err report ->
                  Observer.Reject report
                    |> Expectation.Complete
