module File.Harness exposing (..)

import Harness exposing (use, toRun, setup)
import Spec.Markup as Markup
import Spec.Markup.Selector exposing (..)
import Spec.Markup.Event as Event
import Spec.File
import Spec.Setup as Setup
import File.App as App
import Json.Decode as Json
import Runner


-- Setups

default =
  Setup.initWithModel App.defaultModel
    |> Setup.withView App.view
    |> Setup.withUpdate App.update

setups =
  [ ( "default", setup default )
  ]

-- Steps

selectFile path =
  [ Markup.target << by [ tag "input" ]
  , Event.click
  , Spec.File.select [ Spec.File.atPath path ]
  ]

steps =
  [ ( "selectFile", use Json.string <| toRun selectFile )
  ]


main =
  Runner.harness <| setups ++ steps