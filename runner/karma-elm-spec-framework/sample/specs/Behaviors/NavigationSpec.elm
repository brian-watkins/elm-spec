module Behaviors.NavigationSpec exposing (main)

import Spec exposing (..)
import Spec.Setup as Setup
import Spec.Markup as Markup
import Spec.Markup.Selector exposing (..)
import Spec.Markup.Event as Event
import Application exposing (Model, Msg)
import Url
import Runner


navigationSpec : Spec Model Msg
navigationSpec =
  Spec.describe "on url change"
  [ tagged [ "tagged" ] <|
    scenario "use pushUrl to navigate" (
      given (
        Setup.initForApplication (Application.init ())
          |> Setup.withDocument Application.document
          |> Setup.withUpdate Application.update
          |> Setup.forNavigation { onUrlChange = Application.UrlDidChange, onUrlRequest = Application.onUrlRequest }
          |> Setup.withLocation testUrl
      )
      |> when "the url is changed"
        [ Markup.target << by [ id "push-url-button" ]
        , Event.click
        ]
      |> it "shows a different page" (
        Markup.observeElement
          |> Markup.query << by [ id "fun-page" ]
          |> expect ( Markup.hasText "bowling" )
      )
    )
  ]


testUrl =
  { protocol = Url.Http
  , host = "test-app.com"
  , port_ = Nothing
  , path = "/"
  , query = Nothing
  , fragment = Nothing
  }


main =
  Runner.program
    [ navigationSpec
    ]

