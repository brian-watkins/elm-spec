module Spec.Message exposing
  ( Message
  , for
  , withBody
  , decode
  , belongsTo
  , is
  )

{-| Functions for working with messages that are sent between elm-spec and the JavaScript elm-spec runner.

# Build a Message
@docs Message, for, withBody

# Read a Message
@docs belongsTo, is, decode

-}

import Json.Encode as Encode exposing (Value)
import Json.Decode as Json


{-| Represents a message to pass between elm-spec and the JavaScript elm-spec runner.

The body property is a JSON value.
-}
type alias Message =
  { home: String
  , name: String
  , body: Value
  }


{-| Build a `Message` with the given home and name.

    for "some-plugin" "some-task"

results in:

    { home = "some-plugin"
    , name = "some-task"
    , body = null
    }

-}
for : String -> String -> Message
for home name =
  { home = home
  , name = name
  , body = Encode.null
  }


{-| Set the `body` of a `Message` to some JSON value
-}
withBody : Value -> Message -> Message
withBody value message =
  { message | body = value }


{-| Check whether the message's `home` property is equal to the given string.
-}
belongsTo : String -> Message -> Bool
belongsTo home message =
  message.home == home


{-| Check whether the message's `home` and `name` properties match the given strings.

    { home = "some-plugin"
    , name = "some-task"
    , body = null
    }
      |> is "some-plugin" "some-task"

would return `True`.
-}
is : String -> String -> Message -> Bool
is home name message =
  message.home == home && message.name == name


{-| Decode the JSON `body` of the message to a `Result` type.

The `Err` case contains a string that describes the decoding error.
-}
decode : Json.Decoder a -> Message -> Result String a
decode messageDecoder message =
  Json.decodeValue messageDecoder message.body
    |> Result.mapError Json.errorToString
