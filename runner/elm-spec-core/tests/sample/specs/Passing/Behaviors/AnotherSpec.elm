module Passing.Behaviors.AnotherSpec exposing (..)

import Spec exposing (..)
import Spec.Setup as Setup
import Spec.Markup as Markup
import Spec.Markup.Selector exposing (..)
import Spec.Markup.Event as Event
import Runner
import Main as App


eightClicksSpec : Spec App.Model App.Msg
eightClicksSpec =
  Spec.describe "an html program"
  [ tagged [ "fun" ] <| 
    scenario "a click event" (
      given (
        Setup.initWithModel App.defaultModel
          |> Setup.withUpdate App.update
          |> Setup.withView App.view
      )
      |> when "the button is clicked eight times" (
        (Markup.target << by [ id "my-button" ])
        :: (List.repeat 8 Event.click)
      )
      |> it "renders the count" (
        Markup.observeElement
          |> Markup.query << by [ id "count-results" ]
          |> expect (Markup.hasText "You clicked the button 8 time(s)")
      )
    )
  ]


main =
  Runner.program
    [ eightClicksSpec
    ]