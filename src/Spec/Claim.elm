module Spec.Claim exposing
  ( Claim
  , Verdict(..)
  , satisfying
  , specifyThat
  , isTrue
  , isFalse
  , isEqual
  , isStringContaining
  , isListWithLength
  , isListWhere
  , isListWhereItemAt
  , isSomething
  , isSomethingWhere
  , isNothing
  , mapRejection
  )

{-| A claim is a function that maps a subject to a verdict.

@docs Claim, Verdict

# Basic Claims
@docs isEqual, isTrue, isFalse

# Claims about Strings
@docs isStringContaining

# Claims about Lists
@docs isListWhere, isListWhereItemAt, isListWithLength

# Claims about Maybe types
@docs isSomething, isSomethingWhere, isNothing

# Working with Claims
@docs satisfying, specifyThat, mapRejection

-}

import Spec.Report as Report exposing (Report)


{-| Represents a function from a subject to a verdict.
-}
type alias Claim a =
  a -> Verdict


{-| The result of applying a claim to a subject.

A claim about a subject will either be accepted or rejected.
-}
type Verdict
  = Accept
  | Reject Report


{-| Combine multiple claims into one.

If any of the claims is rejected, then the combined claim is rejected.
-}
satisfying : List (Claim a) -> Claim a
satisfying claims =
  \actual ->
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


{-| Claim that the subject is `True`
-}
isTrue : Claim Bool
isTrue =
  isEqual boolWriter True


{-| Claim that the subject is `False`
-}
isFalse : Claim Bool
isFalse =
  isEqual boolWriter False


boolWriter : Bool -> String
boolWriter b =
  if b == True then
    "True"
  else
    "False"


{-| Claim that the subject is equal to the provided value.

The first argument to this function converts a value of some type to a string, which
is used to produce readable messages if the claim is rejected. Instead of providing
this string-generating function each time, I suggest adding a helper function that just uses the
`Debug.toString` function like so:

    equals : a -> Claim a
    equals =
      Spec.Claim.isEqual Debug.toString

Then just use your `equals` function whenever you need to claim that a subject is equal to some value.
-}
isEqual : (a -> String) -> a -> Claim a
isEqual toString expected =
  \actual ->
    if expected == actual then
      Accept
    else
      Reject <| Report.batch
        [ Report.fact "Actual" <| toString actual
        , Report.fact "does not equal expected" <| toString expected
        ]


{-| Claim that the subject contains the given string the given number of times.

For example,

    "some funny string"
      |> isStringContaining 2 "fun"

would be rejected, since it contains `fun` only once.

-}
isStringContaining : Int -> String -> Claim String
isStringContaining expectedTimes expectedString =
  \actual ->
    let
      count =
        String.indices expectedString actual
          |> List.length
    in
      if count == expectedTimes then
        Accept
      else
        Reject <| Report.batch
          [ Report.fact "Expected" actual
          , Report.fact ("to contain " ++ pluralize expectedTimes "instance" ++ " of") expectedString
          , Report.note <| "but the text was found " ++ pluralize count "time"
          ]


pluralize : Int -> String -> String
pluralize times word =
  if times == 1 then
    "1 " ++ word
  else
    String.fromInt times ++ " " ++ word ++ "s"


{-| Claim that the subject is a list with the given length.
-}
isListWithLength : Int -> Claim (List a)
isListWithLength expected =
  specifyThat List.length <| \actualLength ->
    if actualLength == expected then
      Accept
    else
      Reject <| wrongLength expected actualLength


{-| Claim that the subject is a list where the following claims are satisfied:

- the subject has the same length as the provided list
- for each item in the subject, that item satisfies the corresponding claim in the provided list.

For example:

    [ 1, 2, 3 ]
      |> Spec.Claim.isListWhere
          [ Spec.Claim.isEqual Debug.toString 1
          , Spec.Claim.isEqual Debug.toString 27
          , Spec.Claim.isEqual Debug.toString 3
          ]

would result in a rejected claim, since 2 is not equal to 27.
-}
isListWhere : List (Claim a) -> Claim (List a)
isListWhere claims =
  \actual ->
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
matchList position claims =
  \actual ->
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


{-| Claim that the subject is a list such that:

- there is an item at the given index
- that item satisfies the given claim
-}
isListWhereItemAt : Int -> Claim a -> Claim (List a)
isListWhereItemAt index claim =
  \actualList ->
    case List.head <| List.drop index actualList of
      Just actual ->
        claim actual
          |> mapRejection (\report -> Report.batch
              [ Report.note <| "Item at index " ++ String.fromInt index ++ " did not satisfy claim:"
              , report
              ]
          )
      Nothing ->
        Reject <| Report.batch
          [ Report.fact "Expected item at index" <| String.fromInt index
          , Report.fact "but the list has length" <| String.fromInt <| List.length actualList
          ]


{-| Modify the report associated with a rejected verdict; otherwise, do nothing.
-}
mapRejection : (Report -> Report) -> Verdict -> Verdict
mapRejection mapper verdict =
  case verdict of
    Accept ->
      Accept
    Reject report ->
      Reject <| mapper report


{-| Claim that the subject is the `Just` case of the `Maybe` type.
-}
isSomething : Claim (Maybe a)
isSomething =
  \actual ->
    case actual of
      Just _ ->
        Accept
      Nothing ->
        Reject <| Report.batch
          [ Report.fact "Expected" "something"
          , Report.fact "but found" "nothing"
          ]


{-| Claim that the subject is the `Just` case of the `Maybe` type and that
the associated value satisfies the given claim.

For example,

    Just "apple"
      |> isSomethingWhere (isStringContaining 1 "cheese")

would be rejected.

-}
isSomethingWhere : Claim a -> Claim (Maybe a)
isSomethingWhere claim =
  \actual ->
    case actual of
      Just value ->
        claim value
      Nothing ->
        Reject <| Report.batch
          [ Report.fact "Expected" "something"
          , Report.fact "but found" "nothing"
          ]


{-| Claim that the subject is the `Nothing` case of the `Maybe` type.
-}
isNothing : Claim (Maybe a)
isNothing =
  \actual ->
    case actual of
      Just _ ->
        Reject <| Report.batch
          [ Report.fact "Expected" "nothing"
          , Report.fact "but found" "something"
          ]
      Nothing ->
        Accept


{-| Claim that a value derived from the subject satisfies the given claim.

For example, the following claim:

    { x = 27, y = 31 }
      |> specifyThat .y (isEqual Debug.toString 31)

would be accepted.

-}
specifyThat : (a -> b) -> Claim b -> Claim a
specifyThat mapper claim =
  \actual ->
    claim <| mapper actual