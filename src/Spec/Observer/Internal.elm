module Spec.Observer.Internal exposing
  ( Observer
  , for
  , observeEffects
  , inquire
  , expect
  , focus
  )

import Spec.Message exposing (Message)
import Spec.Claim as Claim exposing (Claim)
import Spec.Scenario.Internal exposing (Expectation, Judgment(..))
import Spec.Step.Context as Context


type Observer model a =
  Observer
    (Claim a -> Expectation model)


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
    \context ->
      Inquire message <|
        \response ->
          mapper response
            |> claim
            |> Complete
