module Spec.Time exposing
  ( withTime
  , withTimezoneOffset
  , tick
  , nextAnimationFrame
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

-}

import Spec.Setup as Setup exposing (Setup)
import Spec.Setup.Internal as Setup
import Spec.Step as Step
import Spec.Step.Command as Command
import Spec.Message as Message
import Spec.Markup.Message as Message
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

Any subscriptions that depend on animation frame updates will be triggered as expected.
-}
nextAnimationFrame : Step.Step model msg
nextAnimationFrame =
  \_ ->
    Command.sendMessage Message.runToNextAnimationFrame
