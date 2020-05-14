module ClickSpec exposing (..)

import Spec exposing (..)
import Spec.Setup as Setup
import Spec.Markup as Markup
import Spec.Markup.Selector exposing (..)
import Spec.Markup.Event as Event
import Spec.Claim as Claim exposing (isStringContaining, isSomethingWhere)
import Spec.Http
import Spec.Http.Route exposing (..)
import Spec.Step as Step
import Spec.Report as Report
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
        , Event.click
        ]
      |> it "renders the count" (
        Markup.observeElement
          |> Markup.query << by [ id "count-results" ]
          |> expect (isSomethingWhere <| Markup.text <| isStringContaining 1 "You clicked the button 3 time(s)")
      )
    )
  , scenario "click to make a request" (
      given (
        Setup.initWithModel App.defaultModel
          |> Setup.withUpdate App.update
          |> Setup.withView App.view
      )
      |> when "the button is clicked three times"
        [ Markup.target << by [ id "request-button" ]
        , \_ -> Step.log <| Report.fact "Hey this is a fun log message!" "2778"
        , Event.click
        ]
      |> it "makes the request" (
        Spec.Http.observeRequests (get "http://fake-api.com/stuff")
          |> expect (Claim.isListWhere
            [ Spec.Http.header "X-Awesome-Header" <| Claim.isSomethingWhere <| Claim.isEqual Debug.toString "some-awesome-value"
            ]
          )
      )
    )
  ]


skippedSpec : Spec App.Model App.Msg
skippedSpec =
  describe "Something skipped"
  [ Runner.skip <| scenario "a click event" (
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
      |> it "renders the count" (
        Markup.observeElement
          |> Markup.query << by [ id "count-results" ]
          |> expect (isSomethingWhere <| Markup.text <| isStringContaining 1 "You clicked the button 3 time(s)")
      )
    )
  ]


main =
  Runner.program
    [ clickSpec
    , skippedSpec
    ]