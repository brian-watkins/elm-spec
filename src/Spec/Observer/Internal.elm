module Spec.Observer.Internal exposing
  ( Observer
  , Judgment(..)
  , Expectation
  , for
  , observeEffects
  , inquire
  , expect
  , focus
  )

import Spec.Message exposing (Message)
import Spec.Claim exposing (Claim, Verdict)
import Spec.Step.Context as Context exposing (Context)


type Observer model a =
  Observer
    (Claim a -> Expectation model)

type alias Expectation model =
  Context model -> Judgment model


type Judgment model
  = Complete Verdict
  | Inquire Message (Message -> Judgment model)



for : (Claim a -> Expectation model) -> Observer model a
for =
  Observer


focus : (Claim b -> Claim a) -> Observer model a -> Observer model b
focus generator (Observer observer) =
  Observer <| \claim ->
    observer <| generator claim


expect : Claim a -> Observer model a -> Expectation model
expect claim (Observer observer) =
  observer claim


observeEffects : (List Message -> a) -> Observer model a
observeEffects mapper =
  Observer <| \claim ->
    \context ->
      Context.effects context
        |> mapper
        |> claim
        |> Complete


inquire : Message -> (Message -> a) -> Observer model a
inquire message mapper =
  Observer <| \claim ->
    \_ ->
      Inquire message <|
        \response ->
          mapper response
            |> claim
            |> Complete
