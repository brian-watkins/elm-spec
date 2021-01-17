module Specs.EventHelpers exposing
  ( eventStepFailsWhenDocumentTargeted
  , eventStepFailsWhenNoElementTargeted
  )

import Spec exposing (..)
import Specs.Helpers exposing (..)
import Spec.Markup as Markup
import Spec.Markup.Selector exposing (..)


eventStepFailsWhenNoElementTargeted subject step =
  scenario "no element is targeted" (
    given (
      subject
    )
    |> when "the event occurs without targeting an element"
      [ step
      ]
    |> itShouldHaveFailedAlready
  )


eventStepFailsWhenDocumentTargeted subject step =
  scenario "document is targeted" (
    given (
      subject
    )
    |> when "document is targeted before step"
      [ Markup.target << document
      , step
      ]
    |> itShouldHaveFailedAlready
  )
