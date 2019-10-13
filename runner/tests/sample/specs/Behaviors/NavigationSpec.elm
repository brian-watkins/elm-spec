module Behaviors.NavigationSpec exposing (main)

import Spec exposing (Spec)
import Spec.Subject as Subject
import Spec.Scenario exposing (..)
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
        Subject.initForApplication (Application.init ())
          |> Subject.withDocument Application.document
          |> Subject.withUpdate Application.update
          |> Subject.onUrlChange Application.UrlDidChange
          |> Subject.withLocation testUrl
      )
      |> when "the url is changed"
        [ target << by [ id "push-url-button" ]
        , Event.click
        ]
      |> it "shows a different page" (
        select << by [ id "fun-page" ]
          |> Markup.expectElement ( Markup.hasText "bowling" )
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

