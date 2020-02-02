module WithMultiDocumentClick.OneSpec exposing (main)

import Spec exposing (..)
import Spec.Setup as Setup
import Spec.Markup as Markup
import Spec.Markup.Selector exposing (..)
import Spec.Markup.Event as Event
import Spec.Http
import Spec.Http.Route exposing (..)
import Spec.Claim as Claim exposing (..)
import Spec.Observer as Observer
import Runner
import Main as App


clickSpec : Spec App.Model App.Msg
clickSpec =
  describe "One HTML program"
  [ scenario "click" (
      given (
        Setup.initWithModel App.defaultModel
          |> Setup.withUpdate App.update
          |> Setup.withView App.view
          |> Setup.withSubscriptions App.subscriptions
      )
      |> when "the document is clicked"
        [ Markup.target << document
        , Event.click
        , Event.click
        , Event.click
        , Event.click
        ]
      |> observeThat
        [ it "records the clicks" (
            Observer.observeModel .clicks
              |> expect (Claim.isEqual Debug.toString 4)
          )
        , it "shows the correct number of requests" (
            Spec.Http.observeRequests (get "http://fun.com/fun")
              |> expect (isListWithLength 4)
          )
        ]
    )
  ]


main =
  Runner.program
    [ clickSpec
    ]