module Animation.Harness exposing (main)

import Harness exposing (Expectation, expect)
import Spec.Setup as Setup
import Spec.Time
import Spec.Observer as Observer
import Spec.Claim exposing (isListWithLength)
import Json.Decode as Json
import Runner
import Animation.App as App



-- Setup


subSetup =
  Setup.initWithModel App.testModel
    |> Setup.withUpdate App.update
    |> Setup.withView App.view
    |> Setup.withSubscriptions App.subscriptions
    |> Spec.Time.allowExtraAnimationFrames


setups =
  [ Harness.assign "default" subSetup
  ]



-- Action


nextAnimationFrame =
  [ Spec.Time.nextAnimationFrame
  ]


stepsToExpose =
  [ Harness.assign "nextAnimationFrame" nextAnimationFrame
  ]



-- Observer


elements expected =
  Observer.observeModel .elements
    |> expect (isListWithLength expected)


claims =
  [ Harness.define "elements" Json.int elements
  ]


main =
  Runner.harness
    { initialStates = setups
    , scripts = stepsToExpose
    , expectations = claims
    }