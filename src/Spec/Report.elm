module Spec.Report exposing
  ( Report
  , batch
  , note
  , fact
  , encode
  , decoder
  )

{-| Functions for building reports that are displayed by the elm-spec JavaScript runner.

# Build a Report
@docs Report, note, fact, batch

# Convert to and from JSON
@docs decoder, encode
-}

import Json.Encode as Encode
import Json.Decode as Json


{-| Represents a collection of notes or facts.

For example, a `Report` can describe why a `Claim` was rejected.
-}
type Report =
  Report (List Line)


type alias Line =
  { statement: String
  , detail: Maybe String
  }


{-| Combine a list of reports into one.
-}
batch : List Report -> Report
batch reports =
  List.map (\(Report report) -> report) reports
    |> List.concat
    |> Report


{-| Generate a `Report` that is a single line of text.
-}
note : String -> Report
note statement =
  Report
    [ { statement = statement
      , detail = Nothing
      }
    ]


{-| Generate a `Report` that is a line of text followed by some details that should be emphasized.
-}
fact : String -> String -> Report
fact statement detail =
  Report
    [ { statement = statement
      , detail = Just detail
      }
    ]


{-| Decode a `Report` from an appropriate JSON object.
-}
decoder : Json.Decoder Report
decoder =
  Json.map Report <| Json.list <| Json.map2 Line
    ( Json.field "statement" Json.string )
    ( Json.field "detail" <| Json.maybe Json.string )


{-| Encode a `Report` into a JSON object.
-}
encode : Report -> Encode.Value
encode (Report report) =
  Encode.list (\line ->
    Encode.object
    [ ( "statement", Encode.string line.statement )
    , ( "detail", line.detail |> Maybe.map Encode.string |> Maybe.withDefault Encode.null )
    ]
  ) report
  
