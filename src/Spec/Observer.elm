module Spec.Observer exposing
  ( Observer
  , Verdict(..)
  , satisfying
  , isEqual
  , isListWithLength
  , isList
  , isListWhereIndex
  , mapRejection
  )

import Spec.Observation.Report as Report exposing (Report)


type alias Observer a =
  a -> Verdict


type Verdict
  = Accept
  | Reject Report


mapRejection : (Report -> Report) -> Verdict -> Verdict
mapRejection mapper verdict =
  case verdict of
    Accept ->
      Accept
    Reject report ->
      Reject <| mapper report


satisfying : List (Observer a) -> Observer a
satisfying observers actual =
  List.foldl (\observer verdict ->
    case observer actual of
      Accept ->
        verdict
      Reject report ->
        case verdict of
          Accept ->
            Reject <| Report.batch
              [ Report.note "Expected all observers to be satisfied, but one or more was rejected"
              , report
              ]
          Reject existingReport ->
            Reject <| Report.batch
              [ existingReport
              , Report.note "and"
              , report
              ]
  ) Accept observers


isEqual : a -> Observer a
isEqual expected actual =
  if expected == actual then
    Accept
  else
    Reject <| Report.batch
      [ Report.fact "Expected" <| toString actual
      , Report.fact "to equal" <| toString expected
      ]


isListWithLength : Int -> Observer (List a)
isListWithLength expected actual =
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


isListWhereIndex : Int -> Observer a -> Observer (List a)
isListWhereIndex index observer list =
  case List.head <| List.drop index list of
    Just actual ->
      observer actual
        |> mapRejection (\report -> Report.batch
            [ Report.note <| "Element at index " ++ String.fromInt index ++ " did not satisfy observer:"
            , report
            ]
        )
    Nothing ->
      Reject <| Report.batch
        [ Report.fact "Expected element at index" <| String.fromInt index
        , Report.fact "but the list has length" <| String.fromInt <| List.length list
        ]


toString : a -> String
toString =
  Elm.Kernel.Debug.toString