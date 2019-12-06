module WithCompilationError.ClickSpec exposing (..)

import Spec exposing (..)
import Spec.Subject as Subject
import Spec.Markup as Markup
import Spec.Markup.Selector exposing (..)
import Spec.Markup.Event as Event
import Runner
import Main as App


clickSpec : Spec App.Model App.Msg
clickSpec =
  Spec.describe "an html program"
  [ scenario "a click event" (
      given (
        Subject.initWithModel App.defaultModel
          |> Subject.withUpdate App.update
          |> Subject.withView App.view
      )
      |> when "the button is clicked three times"
        [ Markup.target << by [ id "my-button" ]
        , Event.clicksssss
        , Event.click
        , Event.click
        ]
      |> it "renders the count" (
        Markup.observeElement
          |> Markup.query << by [ id "count-results" ]
          |> expect (Markup.hasText "You clicked the button 3 time(s)")
      )
    )
  ]


main =
  Runner.program
    [ clickSpec
    ]