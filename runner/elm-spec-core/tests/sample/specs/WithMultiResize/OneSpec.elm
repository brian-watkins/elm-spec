module WithMultiResize.OneSpec exposing (main)

import Spec exposing (..)
import Spec.Setup as Setup
import Spec.Markup as Markup
import Spec.Markup.Selector exposing (..)
import Spec.Navigator as Navigator
import Spec.Http
import Spec.Http.Route exposing (..)
import Spec.Claim as Claim exposing (..)
import Spec.Observer as Observer
import Runner
import Main as App


resizeSpec : Spec App.Model App.Msg
resizeSpec =
  describe "One HTML program"
  [ scenario "resize" (
      given (
        Setup.initWithModel App.defaultModel
          |> Setup.withUpdate App.update
          |> Setup.withView App.view
          |> Setup.withSubscriptions App.subscriptions
      )
      |> when "the browser window size changes"
        [ Navigator.resize (600, 800)
        ]
      |> observeThat
        [ it "records the changes" (
            Observer.observeModel .sizes
              |> expect (Claim.isEqual Debug.toString [ (600, 800) ])
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