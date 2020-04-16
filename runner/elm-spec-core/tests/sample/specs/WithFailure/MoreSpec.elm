module WithFailure.MoreSpec exposing (..)

import Spec exposing (..)
import Spec.Setup as Setup
import Spec.Markup as Markup
import Spec.Markup.Selector exposing (..)
import Spec.Markup.Event as Event
import Spec.Claim exposing (isStringContaining, isSomethingWhere)
import Runner
import Main as App


clickSpec : Spec App.Model App.Msg
clickSpec =
  Spec.describe "an html program"
  [ scenario "another click event" (
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
        , Event.click
        ]
      |> observeThat
        [ it "renders the count" (
            Markup.observeElement
              |> Markup.query << by [ id "count-results" ]
              |> expect (isSomethingWhere <| Markup.text <| isStringContaining 1 "You clicked the button 3 time(s)")
          )
        , it "fails in another way" (
            Markup.observeElement
              |> Markup.query << by [ id "does-not-exist" ]
              |> expect (isSomethingWhere <| Markup.text <| isStringContaining 1 "Something")
          )
        ]
    )
  ]


main =
  Runner.program
    [ clickSpec
    ]