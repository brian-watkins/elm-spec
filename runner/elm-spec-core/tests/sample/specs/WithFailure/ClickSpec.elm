module WithFailure.ClickSpec exposing (..)

import Spec exposing (..)
import Spec.Setup as Setup
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
        Setup.initWithModel App.defaultModel
          |> Setup.withUpdate App.update
          |> Setup.withView App.view
      )
      |> when "the button is clicked three times"
        [ Markup.target << by [ id "my-button" ]
        , Event.click
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