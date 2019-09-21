module InputSpec exposing (..)

import Spec exposing (Spec)
import Spec.Subject as Subject
import Spec.Scenario exposing (..)
import Spec.Html as Markup
import Spec.Html.Selector exposing (..)
import Spec.Html.Event as Event
import Runner
import Main as App

inputSpec : Spec App.Model App.Msg
inputSpec =
  Spec.describe "an html program"
  [ scenario "an input event" (
      Subject.initWithModel App.defaultModel
        |> Subject.withUpdate App.update
        |> Subject.withView App.view
    )
    |> when "some text is input"
      [ target << by [ id "my-input" ]
      , Event.input "Here is some fun text!"
      ]
    |> it "renders the text on the view" (
      select << by [ id "input-results" ]
        |> Markup.expectElement (Markup.hasText "You typed: Here is some fun text!")
    )
  ]


differentInputSpec : Spec App.Model App.Msg
differentInputSpec =
  Spec.describe "an html program"
  [ scenario "another input event" (
      Subject.initWithModel App.defaultModel
        |> Subject.withUpdate App.update
        |> Subject.withView App.view
    )
    |> when "some text is input"
      [ target << by [ id "my-input" ]
      , Event.input "Here is some awesome text!"
      ]
    |> it "renders the text on the view" (
      select << by [ id "input-results" ]
        |> Markup.expectElement (Markup.hasText "You typed: Here is some awesome text!")
    )
    |> it "does not record any clicks" (
      select << by [ id "count-results" ]
        |> Markup.expectElement (Markup.hasText "You clicked the button 0 time(s)")
    )
  ]


main =
  Runner.program
    [ inputSpec
    , differentInputSpec
    ]