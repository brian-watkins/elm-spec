module InputSpec exposing (..)

import Spec exposing (Spec)
import Spec.Subject as Subject
import Spec.Scenario exposing (..)
import Spec.Markup as Markup
import Spec.Markup.Selector exposing (..)
import Spec.Markup.Event as Event
import Runner
import Main as App

inputSpec : Spec App.Model App.Msg
inputSpec =
  Spec.describe "an html program"
  [ scenario "an input event" (
      given (
        Subject.initWithModel App.defaultModel
          |> Subject.withUpdate App.update
          |> Subject.withView App.view
      )
      |> when "some text is input"
        [ Markup.target << by [ id "my-input" ]
        , Event.input "Here is some fun text!"
        ]
      |> it "renders the text on the view" (
        Markup.observeElement
          |> Markup.query << by [ id "input-results" ]
          |> expect (Markup.hasText "You typed: Here is some fun text!")
      )
    )
  ]


differentInputSpec : Spec App.Model App.Msg
differentInputSpec =
  Spec.describe "an html program"
  [ scenario "another input event" (
      given (
        Subject.initWithModel App.defaultModel
          |> Subject.withUpdate App.update
          |> Subject.withView App.view
      )
      |> when "some text is input"
        [ Markup.target << by [ id "my-input" ]
        , Event.input "Here is some awesome text!"
        ]
      |> observeThat
        [ it "renders the text on the view" (
            Markup.observeElement
              |> Markup.query << by [ id "input-results" ]
              |> expect (Markup.hasText "You typed: Here is some awesome text!")
          )
        , it "does not record any clicks" (
            Markup.observeElement
              |> Markup.query << by [ id "count-results" ]
              |> expect (Markup.hasText "You clicked the button 0 time(s)")
          )
        ]
    )
  ]


main =
  Runner.program
    [ inputSpec
    , differentInputSpec
    ]