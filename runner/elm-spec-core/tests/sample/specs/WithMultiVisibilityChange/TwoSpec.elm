module WithMultiVisibilityChange.TwoSpec exposing (main)

import Spec exposing (..)
import Spec.Setup as Setup
import Spec.Markup as Markup
import Spec.Markup.Selector exposing (..)
import Spec.Navigator as Navigator
import Spec.Http
import Spec.Http.Route exposing (..)
import Spec.Claim as Claim exposing (..)
import Spec.Observer as Observer
import Spec.Time
import Runner
import Main as App


visibilityChangeSpec : Spec App.Model App.Msg
visibilityChangeSpec =
  describe "Two HTML program"
  [ scenario "visiblity changes" (
      given (
        Setup.initWithModel App.defaultModel
          |> Setup.withUpdate App.update
          |> Setup.withView App.view
          |> Setup.withSubscriptions App.subscriptions
      )
      |> when "the visibility changes"
        [ Navigator.hide
        , Navigator.show
        , Navigator.hide
        , Navigator.show
        , Navigator.hide
        ]
      |> observeThat
        [ it "records the changes" (
            Observer.observeModel .visibilityChanges
              |> expect (Claim.isEqual Debug.toString 5)
          )
        , it "shows the correct number of requests" (
            Spec.Http.observeRequests (get "http://fun.com/fun")
              |> expect (isListWithLength 2)
          )
        ]
    )
  ]


main =
  Runner.program
    [ visibilityChangeSpec
    ]