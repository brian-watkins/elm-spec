module Spec.Time exposing
  ( withTime
  , withTimezoneOffset
  , tick
  , nextAnimationFrame
  )

{-| Functions for working with time during a spec.

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
tick : Int -> Step.Context model -> Step.Command msg
tick duration _ =
  Message.for "_time" "tick"
    |> Message.withBody (Encode.int duration)
    |> Command.sendMessage


{-| A step that simulates waiting for the next animation frame.

Any subscriptions that depend on animation frame updates will be triggered as expected.
-}
nextAnimationFrame : Step.Context model -> Step.Command msg
nextAnimationFrame _ =
  Command.sendMessage
    Message.runToNextAnimationFrame
