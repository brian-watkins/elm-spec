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

Note that, for all other steps, an animation frame runs at the end of the step, updating the view. But
for `Spec.Time.nextAnimationFrame` sometimes you may need to trigger the frame that update the view explicitly.

Consider another example. Suppose you have a subscription to `Browser.Events.onAnimationFrame` that sends a
message `AnimationFrame` on each animation frame. And suppose your update function looks something like:

```
update : Model -> Msg -> (Model, Cmd Msg)
update model msg =
  case msg of
    AnimationFrame ->
      ( { model | frames = model.frames + 1 }
      , Cmd.none
      )
```

Now, you could have a scenario that checks to see that the view is updated with the number of frames:

```
frameSpce =
  describe "view changes on animation frame"
  [ scenario "three animation frames" (
      given (
        Spec.Setup.initWithModel { frames = 0 }
          |> ...
      )
      |> when "two more frames pass"
        [ Spec.Time.nextAnimationFrame
        , Spec.Time.nextAnimationFrame
        ]
      |> it "displays the count in the view" (
        Spec.Markup.observeElement
          |> Spec.Markup.query << by [ id "frame-count" ]
          |> expect (Spec.Claim.isSomethingWhere <|
            Spec.Markup.text <|
            Spec.Claim.isEqual Debug.toString "2 frames!"
          )
      )
    )
  ]
```

Note that by the end of this scenario, three animation frames have passed: 1 after the initial
command, and then 2 explicitly. If you were to observe the model after this scenario, `frames` would be `3`, but
the view only shows `2 frames!`. What's happening?

When you call `Spec.Time.nextAnimationFrame` it runs only one animation frame. In this case,
that animation frame triggers the subscription, which calls your update function and changes the model. But
another animation frame must pass before the view is rendered with the updated model. The second call to
`Spec.Time.nextAnimationFrame` will update the view, but it will be based on the state of the model at that
time, which had `frames` equal to `2`.

In any case, the point here is that when you write a spec that depends on triggering individual animation
frames you may unfortunately start to see some details of the Elm runtime implementation leak into your specs.

Elm-spec can detect when there are animation frame tasks remaining at the end of a step and will warn you to
address this. You can disable this warning with [allowExtraAnimationFrames](#allowExtraAnimationFrames).

-}
nextAnimationFrame : Step.Step model msg
nextAnimationFrame =
  \_ ->
    Command.sendMessage Message.runToNextAnimationFrame
