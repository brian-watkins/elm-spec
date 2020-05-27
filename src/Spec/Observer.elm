module Spec.Observer exposing
  ( Observer
  , observeModel
  , mapRejection
  , observeResult
  , focus
  )

{-| An observer examines some part of the world so a claim can be made about it.

This module contains functions for working with observers at a high level.

Check out `Spec.Markup`, `Spec.Navigator`, `Spec.Http`, `Spec.File`,
`Spec.Port`, and `Spec.Witness` for more observers.

# Build Observers
@docs Observer, observeModel

# Work with Observers
@docs observeResult, mapRejection, focus

-}

import Spec.Observer.Internal as Internal
import Spec.Message as Message exposing (Message)
import Spec.Claim as Claim exposing (Claim)
import Spec.Step.Context as Context
import Spec.Scenario.Internal as Scenario exposing (Judgment(..))
import Spec.Report exposing (Report)


{-| An `Observer` examines some particular part of the world so that a
claim can be evaluated with respect to it.
-}
type alias Observer model a =
  Internal.Observer model a


{-| Observe some aspect of the model of the program whose behavior is being described in this scenario.

For example, if the program model looks like `{ score: 27 }`, then you could observe the
score like so:

    Spec.it "has the correct score" (
      observeModel .score
        |> Spec.expect 
          (Spec.Claim.isEqual Debug.toString 27)
    )

To observe the entire model, just use `identity` as the argument.

Check out `Spec.Markup`, `Spec.Navigator`,
`Spec.Http`, `Spec.File`, `Spec.Port`, and `Spec.Witness`
for observers that evaluate claims with respect to the world outside the program.

-}
observeModel : (model -> a) -> Observer model a
observeModel mapper =
  Internal.for <| \claim ->
    \context ->
      Context.model context
        |> Claim.specifyThat mapper claim
        |> Complete


{-| Create a new `Observer` that will evaluate a `Claim` with respect to
the successful `Result` observed by the given `Observer`. If the `Result`
fails then the `Claim` will be rejected with the report that is the `Err`
value.

For example,

    Spec.Observer.observeModel (\_ -> Err <| Report.note "This should fail")
      |> Spec.Observer.observeResult
      |> Spec.expect (Spec.Claim.isEqual Debug.toString "Fun")

will be rejected with the message: This should fail.
-}
observeResult : Observer model (Result Report a) -> Observer model a
observeResult =
  focus <| \claim ->
    \actual ->
      case actual of
        Ok value ->
          claim value
        Err report ->
          Claim.Reject report


{-| Create a new `Observer` that will map the `Report` created if the `Claim` is rejected.
-}
mapRejection : (Report -> Report) -> Observer model a -> Observer model a
mapRejection mapper =
  focus <| \claim ->
    \actual ->
      case claim actual of
        Claim.Accept ->
          Claim.Accept
        Claim.Reject report ->
          Claim.Reject <| mapper report


{-| Create a new `Observer` that evaluates a claim with respect to a particular aspect of the world
observed by the given observer.

Consider an `Observer model (Maybe HtmlElement)`, which observes all aspects of a `Maybe HtmlElement`.
Create an `Observer` that focuses on just the text of an existing `HtmlElement` like so:

    Spec.Markup.observeElement
      |> Spec.Markup.query << by [ id "some-element" ]
      |> focus Spec.Claim.isSomethingWhere
      |> focus Spec.Markup.text
      |> Spec.expect (
        Spec.Claim.isEqual Debug.toString "Something cool!"
      )

If the element doesn't exist, then the `isSomethingWhere` claim would fail, and subsequent claims would not be evaluated by the observer.

You could then abstract this into a helper function like so:

    expectText : Claim String -> Observer model (Maybe HtmlElement) -> Expectation model
    expectText claim observer =
      observer
        |> focus Spec.Claim.isSomethingWhere
        |> focus Spec.Markup.text
        |> Spec.expect claim

And then you could write:

    Spec.Markup.observeElement
      |> Spec.Markup.query << by [ id "some-element" ]
      |> expectText (
        Spec.Claim.isEqual Debug.toString "Something cool!"
      )

-}
focus : (Claim b -> Claim a) -> Observer model a -> Observer model b
focus =
  Internal.focus
