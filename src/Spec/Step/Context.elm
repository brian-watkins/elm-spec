module Spec.Step.Context exposing
  ( Context
  , for
  , withEffects
  , model
  , effects
  )

import Spec.Message exposing (Message)


type Context model =
  Context
    { model: model
    , effects: List Message
    }


for : model -> Context model
for programModel =
  Context
    { model = programModel
    , effects = []
    }


withEffects : List Message -> Context model -> Context model
withEffects programEffects (Context context) =
  Context
    { context | effects = programEffects }


model : Context model -> model
model (Context context) =
  context.model


effects : Context model -> List Message
effects (Context context) =
  context.effects