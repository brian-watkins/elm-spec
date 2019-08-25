module Spec.Actual exposing
  ( Actual(..)
  , model
  , effects
  , inquire
  , map
  )

import Spec.Message exposing (Message)


type Actual model a
  = Model (model -> a)
  | Effects (List Message -> a)
  | Inquiry Message (Message -> a)


model : Actual model model
model =
  Model identity


effects : Actual model (List Message)
effects =
  Effects identity


inquire : Message -> Actual model Message
inquire message =
  Inquiry message identity


map : (a -> b) -> Actual model a -> Actual model b
map mapper actual =
  case actual of
    Model generator ->
      Model (generator >> mapper)
    Effects generator ->
      Effects (generator >> mapper)
    Inquiry message generator ->
      Inquiry message (generator >> mapper)
