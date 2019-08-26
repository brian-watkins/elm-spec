module Spec.Observer.Report exposing
  ( Report
  , batch
  , note
  , fact
  , encoder
  , decoder
  )

import Json.Encode as Encode
import Json.Decode as Json


type alias Report =
  List Line


type alias Line =
  { statement: String
  , detail: Maybe String
  }


batch : List Report -> Report
batch =
  List.concat


note : String -> Report
note statement =
  [ { statement = statement
    , detail = Nothing
    }
  ]


fact : String -> String -> Report
fact statement detail =
  [ { statement = statement
    , detail = Just detail
    }
  ]


decoder : Json.Decoder Report
decoder =
  Json.list <| Json.map2 Line
    ( Json.field "statement" Json.string )
    ( Json.field "detail" <| Json.maybe Json.string )


encoder : Report -> Encode.Value
encoder =
  Encode.list (\line ->
    Encode.object
    [ ( "statement", Encode.string line.statement )
    , ( "detail", line.detail |> Maybe.map Encode.string |> Maybe.withDefault Encode.null )
    ]
  )
  
