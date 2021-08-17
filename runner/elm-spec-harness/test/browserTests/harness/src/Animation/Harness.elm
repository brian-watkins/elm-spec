module Animation.Harness exposing (main)

import Harness exposing (Expectation, expect, use, run, toObserve, setup)
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
  [ ( "default", setup subSetup )
  ]



-- Action


nextAnimationFrame =
  [ Spec.Time.nextAnimationFrame
  ]


steps =
  [ ( "nextAnimationFrame", run nextAnimationFrame )
  ]



-- Observer


elements expected =
  Observer.observeModel .elements
    |> expect (isListWithLength expected)


claims =
  [ ( "elements", use Json.int <| toObserve elements )
  ]


main =
  Runner.harness <| setups ++ steps ++ claims