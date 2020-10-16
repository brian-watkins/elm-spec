module Spec.Time exposing
  ( withTime
  , withTimezoneOffset
  , tick
  , nextAnimationFrame
  , allowExtraAnimationFrames
  )

{-| Functions for working with time during a spec.

Suppose you use `Time.every` to increment a count in your model after each second.
Here's a spec you could use to describe that behavior:

    Spec.describe "seconds counter"
    [ Spec.scenario "some seconds pass" (
        Spec.given (
          Spec.Setup.init (App.init testFlags)
            |> Spec.Setup.withView App.view
            |> Spec.Setup.withUpdate App.update
        )
        |> when "some time passes"
          [ Spec.Time.tick 3000
          ]
        |> it "increments the counter" (
          Spec.Observer.observeModel .seconds
            |> Spec.expect (Spec.Claim.isEqual Debug.toString 3)
        )
      )
    ]

# Set Up at a Time
@docs withTime, withTimezoneOffset

# Pass the Time
@docs tick, nextAnimationFrame

# Handle Special Cases
@docs allowExtraAnimationFrames

-}

import Spec.Setup as Setup exposing (Setup)
import Spec.Setup.Internal as Setup
import Spec.Step as Step
import Spec.Step.Command as Command
import Spec.Message as Message
import Spec.Scenario.Message as Message
import Json.Encode as Encode


{-| Set up the scenario at a particular time.

Provide the number of milliseconds since the UNIX epoch.
-}
withTime : Int -> Setup model msg -> Setup model msg
withTime posix =
  Message.for "_time" "set-time"
    |> Message.withBody (Encode.int posix)
    |> Setup.configure


{-| Set up the scenario at a particular timezone offset.

Provide the timezone offste in minutes.
-}
withTimezoneOffset : Int -> Setup model msg -> Setup model msg
withTimezoneOffset zoneOffset =
  Message.for "_time" "set-timezone"
    |> Message.withBody (Encode.int zoneOffset)
    |> Setup.configure


{-| Set up the scenario to allow steps that result in effects that wait on the *next* animation frame.

By default, elm-spec rejects any scenario with a step that results in effects that reuire extra
animation frames to resolve, since you may need to use [nextAnimationFrame](#nextAnimationFrame) to
trigger the behavior you want to describe.

Use this function to allow such a scenario to continue.

See [nextAnimationFrame](#nextAnimationFrame) for more information.

-}
allowExtraAnimationFrames : Setup model msg -> Setup model msg
allowExtraAnimationFrames =
  Message.for "_scenario" "warn-on-extra-animation-frames"
    |> Message.withBody (Encode.bool False)
    |> Setup.configure


{-| A step that simulates waiting for some number of milliseconds to pass.

Any subscriptions that depend on the passage of time will be triggered as expected.
-}
tick : Int -> Step.Step model msg
tick duration =
  \_ ->
    Message.for "_time" "tick"
      |> Message.withBody (Encode.int duration)
      |> Command.sendMessage


{-| A step that simulates waiting for the next animation frame.

Any subscriptions or other effects that depend on animation frame updates will be triggered as expected, and
the view will be re-rendered.

Note that some commands like those in the `Browser.Dom` module wait for the next animation frame before
completing. For example, the following `Cmd`

```
Browser.Dom.getElement "fun-element"
  |> Task.andThen (\element -> 
    Browser.Dom.setViewport 0.0 element.y
  )
  |> Task.attempt (\_ -> NoOp)
```

will wait for the next animation frame to get the element and then wait for another animation frame
before setting the viewport.

Elm-spec runs any tasks waiting on the current animation frame at the end of each step in the scenario script.
But sometimes animation frame tasks will remain because there are commands or subscriptions
waiting on the *next* animation frame. In such cases, you can use `nextAnimationFrame` to simply wait for
the next animation frame, allowing these commands or subscriptions to complete -- if that is useful for
triggering the behavior described in this scenario.

So, in the example above, you would need to run `Spec.Time.nextAnimationFrame` after the step that triggers the
command so that the `Browser.Dom.setViewport` command will complete.

Elm-spec can detect when there are animation frame tasks remaining at the end of a step and will warn you to
address this. You can disable this warning with [allowExtraAnimationFrames](#allowExtraAnimationFrames).

-}
nextAnimationFrame : Step.Step model msg
nextAnimationFrame =
  \_ ->
    Command.sendMessage Message.runToNextAnimationFrame
