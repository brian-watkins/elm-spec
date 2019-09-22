module Behaviors.AnotherSpec exposing (..)

import Spec exposing (Spec)
import Spec.Subject as Subject
import Spec.Scenario exposing (..)
import Spec.Markup as Markup
import Spec.Markup.Selector exposing (..)
import Spec.Markup.Event as Event
import Runner
import Main as App


eightClicksSpec : Spec App.Model App.Msg
eightClicksSpec =
  Spec.describe "an html program"
  [ scenario "a click event" (
      Subject.initWithModel App.defaultModel
        |> Subject.withUpdate App.update
        |> Subject.withView App.view
    )
    |> when "the button is clicked eight times" (
      (target << by [ id "my-button" ])
      :: (List.repeat 8 Event.click)
    )
    |> it "renders the count" (
      select << by [ id "count-results" ]
        |> Markup.expectElement (Markup.hasText "You clicked the button 8 time(s)")
    )
  ]


main =
  Runner.program
    [ eightClicksSpec
    ]