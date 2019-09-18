module Spec.Observer exposing
  ( Observer
  , Verdict(..)
  , isEqual
  , hasLength
  )

import Spec.Observation.Report as Report exposing (Report)


type alias Observer a =
  a -> Verdict


type Verdict
  = Accept
  | Reject Report


isEqual : a -> Observer a
isEqual expected actual =
  if expected == actual then
    Accept
  else
    Reject <| Report.batch
      [ Report.fact "Expected" <| toString expected
      , Report.fact "to equal" <| toString actual
      ]


hasLength : Int -> Observer (List a)
hasLength expected list =
  let
    actual = List.length list
  in
    if actual == expected then
      Accept
    else
      Reject <| Report.batch
        [ Report.fact "Expected list to have length" <| toString expected
        , Report.fact "but it has length" <| toString <| actual
        ]


toString : a -> String
toString =
  Elm.Kernel.Debug.toString