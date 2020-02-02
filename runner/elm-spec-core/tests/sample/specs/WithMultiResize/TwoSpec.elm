module WithMultiResize.TwoSpec exposing (main)

import Spec exposing (..)
import Spec.Setup as Setup
import Spec.Markup as Markup
import Spec.Markup.Selector exposing (..)
import Spec.Markup.Event as Event
import Spec.Http
import Spec.Http.Route exposing (..)
import Spec.Claim as Claim exposing (..)
import Spec.Observer as Observer
import Spec.Time
import Runner
import Main as App


resizeSpec : Spec App.Model App.Msg
resizeSpec =
  describe "Two HTML program"
  [ scenario "resize" (
      given (
        Setup.initWithModel App.defaultModel
          |> Setup.withUpdate App.update
          |> Setup.withView App.view
          |> Setup.withSubscriptions App.subscriptions
      )
      |> when "the window size changes"
        [ Event.resizeWindow (200, 450)
        ]
      |> observeThat
        [ it "records the changes" (
            Observer.observeModel .sizes
              |> expect (Claim.isEqual Debug.toString [ (200, 450) ])
          )
        , it "shows the correct number of requests" (
            Spec.Http.observeRequests (get "http://fun.com/fun")
              |> expect (isListWithLength 1)
          )
        ]
    )
  ]


main =
  Runner.program
    [ resizeSpec
    ]