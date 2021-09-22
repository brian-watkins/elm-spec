module Animation.Harness exposing (main)

import Harness exposing (Expectation, expect, steps, stepsFrom, expectation, expectationFrom, setup, setupFrom)
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
  [ Harness.export "default" <| setup subSetup
  ]



-- Action


nextAnimationFrame =
  [ Spec.Time.nextAnimationFrame
  ]


stepsToExpose =
  [ Harness.export "nextAnimationFrame" <| steps nextAnimationFrame
  ]



-- Observer


elements expected =
  Observer.observeModel .elements
    |> expect (isListWithLength expected)


claims =
  [ Harness.export "elements" <| expectationFrom Json.int elements
  ]


main =
  Runner.harness <| setups ++ stepsToExpose ++ claims