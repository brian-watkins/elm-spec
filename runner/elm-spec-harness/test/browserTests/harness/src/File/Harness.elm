module File.Harness exposing (..)

import Harness
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
  [ Harness.assign "default" default
  ]

-- Steps

selectFile path =
  [ Markup.target << by [ tag "input" ]
  , Event.click
  , Spec.File.select [ Spec.File.atPath path ]
  ]

steps =
  [ Harness.define "selectFile" Json.string selectFile
  ]


main =
  Runner.harness
    { initialStates = setups
    , scripts = steps
    , expectations = []
    }