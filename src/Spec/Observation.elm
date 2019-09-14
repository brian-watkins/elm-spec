module Spec.Observation exposing
  ( Selection
  , selectModel
  , selectEffects
  , inquire
  , mapSelection
  , Expectation
  , Judgment
  , expect
  )

import Spec.Message as Message exposing (Message)
import Spec.Observer as Observer exposing (Observer, Verdict)
import Spec.Observation.Internal as Internal


type Selection model a
  = Model (model -> a)
  | Effects (List Message -> a)
  | Inquiry Message (Message -> a)


type alias Judgment model =
  Internal.Judgment model


type alias Expectation model =
  Internal.Expectation model


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
  Internal.Expectation <|
    \context ->
      case selection of
        Model mapper ->
          mapper context.model
            |> observer
            |> Internal.Complete
        Effects mapper ->
          mapper context.effects
            |> observer
            |> Internal.Complete
        Inquiry message mapper ->
          Internal.AndThen message <|
            \inquiryResult ->
              mapper inquiryResult
                |> observer
                |> Internal.Complete
