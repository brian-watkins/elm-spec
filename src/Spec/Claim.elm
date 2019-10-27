module Spec.Claim exposing
  ( Claim
  , Verdict(..)
  , satisfying
  , isTrue
  , isFalse
  , isEqual
  , isListWithLength
  , isList
  , isListWhereIndex
  )

import Spec.Observation.Report as Report exposing (Report)


type alias Claim a =
  a -> Verdict


type Verdict
  = Accept
  | Reject Report


satisfying : List (Claim a) -> Claim a
satisfying claims actual =
  List.foldl (\claim verdict ->
    case claim actual of
      Accept ->
        verdict
      Reject report ->
        case verdict of
          Accept ->
            Reject <| Report.batch
              [ Report.note "Expected all claims to be satisfied, but one or more were rejected"
              , report
              ]
          Reject existingReport ->
            Reject <| Report.batch
              [ existingReport
              , Report.note "and"
              , report
              ]
  ) Accept claims


isTrue : Claim Bool
isTrue =
  isEqual boolWriter True


isFalse : Claim Bool
isFalse =
  isEqual boolWriter False


boolWriter : Bool -> String
boolWriter b =
  if b == True then
    "True"
  else
    "False"


isEqual : (a -> String) -> a -> Claim a
isEqual toString expected actual =
  if expected == actual then
    Accept
  else
    Reject <| Report.batch
      [ Report.fact "Expected" <| toString actual
      , Report.fact "to equal" <| toString expected
      ]


isListWithLength : Int -> Claim (List a)
isListWithLength expected actual =
  let
    actualLength = List.length actual
  in
    if actualLength == expected then
      Accept
    else
      Reject <| wrongLength expected actualLength


isList : List (Claim a) -> Claim (List a)
isList claims actual =
  if List.length claims == List.length actual then
    matchList 1 claims actual
  else
    Reject <| Report.batch
      [ Report.note "List failed to match"
      , wrongLength (List.length claims) (List.length actual)
      ]


wrongLength : Int -> Int -> Report
wrongLength expected actual =
  Report.batch
  [ Report.fact "Expected list to have length" <| String.fromInt expected
  , Report.fact "but it has length" <| String.fromInt actual
  ]


matchList : Int -> List (Claim a) -> Claim (List a)
matchList position claims actual =
  case ( claims, List.head actual ) of
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


isListWhereIndex : Int -> Claim a -> Claim (List a)
isListWhereIndex index claim actualList =
  case List.head <| List.drop index actualList of
    Just actual ->
      claim actual
        |> mapRejection (\report -> Report.batch
            [ Report.note <| "Element at index " ++ String.fromInt index ++ " did not satisfy claim:"
            , report
            ]
        )
    Nothing ->
      Reject <| Report.batch
        [ Report.fact "Expected element at index" <| String.fromInt index
        , Report.fact "but the list has length" <| String.fromInt <| List.length actualList
        ]


mapRejection : (Report -> Report) -> Verdict -> Verdict
mapRejection mapper verdict =
  case verdict of
    Accept ->
      Accept
    Reject report ->
      Reject <| mapper report
