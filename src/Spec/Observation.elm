module Spec.Observation exposing
  ( Observation
  , Selection
  , selectModel
  , selectEffects
  , inquire
  , mapSelection
  , Expectation
  , expect
  )

import Spec.Message as Message exposing (Message)
import Spec.Observer as Observer exposing (Observer, Verdict)
import Spec.Observation.Expectation as Expectation


type alias Observation model =
  { description: String
  , expectation: Expectation model
  }


type Selection model a
  = Model (model -> a)
  | Effects (List Message -> a)
  | Inquiry Message (Message -> a)


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
  Inquiry message identity


mapSelection : (a -> b) -> Selection model a -> Selection model b
mapSelection mapper selection =
  case selection of
    Model generator ->
      Model (generator >> mapper)
    Effects generator ->
      Effects (generator >> mapper)
    Inquiry message generator ->
      Inquiry message (generator >> mapper)


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
              mapper inquiryResult
                |> observer
                |> Expectation.Complete
