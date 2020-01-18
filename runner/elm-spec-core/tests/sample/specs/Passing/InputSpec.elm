module Passing.InputSpec exposing (..)

import Spec exposing (..)
import Spec.Setup as Setup
import Spec.Markup as Markup
import Spec.Markup.Selector exposing (..)
import Spec.Markup.Event as Event
import Spec.Claim exposing (isStringContaining, isSomethingWhere)
import Runner
import Main as App

inputSpec : Spec App.Model App.Msg
inputSpec =
  Spec.describe "an html program"
  [ scenario "an input event" (
      given (
        Setup.initWithModel App.defaultModel
          |> Setup.withUpdate App.update
          |> Setup.withView App.view
      )
      |> when "some text is input"
        [ Markup.target << by [ id "my-input" ]
        , Event.input "Here is some fun text!"
        ]
      |> it "renders the text on the view" (
        Markup.observeElement
          |> Markup.query << by [ id "input-results" ]
          |> expect (isSomethingWhere <| Markup.text <| isStringContaining 1 "You typed: Here is some fun text!")
      )
    )
  ]


differentInputSpec : Spec App.Model App.Msg
differentInputSpec =
  Spec.describe "an html program"
  [ scenario "another input event" (
      given (
        Setup.initWithModel App.defaultModel
          |> Setup.withUpdate App.update
          |> Setup.withView App.view
      )
      |> when "some text is input"
        [ Markup.target << by [ id "my-input" ]
        , Event.input "Here is some awesome text!"
        ]
      |> observeThat
        [ it "renders the text on the view" (
            Markup.observeElement
              |> Markup.query << by [ id "input-results" ]
              |> expect (isSomethingWhere <| Markup.text <| isStringContaining 1 "You typed: Here is some awesome text!")
          )
        , it "does not record any clicks" (
            Markup.observeElement
              |> Markup.query << by [ id "count-results" ]
              |> expect (isSomethingWhere <| Markup.text <| isStringContaining 1 "You clicked the button 0 time(s)")
          )
        ]
    )
  ]


main =
  Runner.program
    [ inputSpec
    , differentInputSpec
    ]