module Spec.Observer exposing
  ( Observer
  , Verdict(..)
  , isEqual
  , hasLength
  , isList
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
hasLength expected actual =
  let
    actualLength = List.length actual
  in
    if actualLength == expected then
      Accept
    else
      Reject <| wrongLength expected actualLength


isList : List (Observer a) -> Observer (List a)
isList observers actual =
  if List.length observers == List.length actual then
    matchList 1 observers actual
  else
    Reject <| Report.batch
      [ Report.note "List failed to match"
      , wrongLength (List.length observers) (List.length actual)
      ]


wrongLength : Int -> Int -> Report
wrongLength expected actual =
  Report.batch
  [ Report.fact "Expected list to have length" <| toString expected
  , Report.fact "but it has length" <| toString actual
  ]


matchList : Int -> List (Observer a) -> Observer (List a)
matchList position observers actual =
  case ( observers, List.head actual ) of
    ( [], Nothing ) ->
      Accept
    ( next :: remaining, Just head ) ->
      case next head of
        Accept ->
          matchList (position + 1) remaining <| List.drop 1 actual
        Reject report ->
          Reject <| Report.batch
            [ Report.note <| "List failed to match at position " ++ String.fromInt position
            , report
            ]
    _ ->
      Reject <| Report.note "Something crazy happened"


toString : a -> String
toString =
  Elm.Kernel.Debug.toString