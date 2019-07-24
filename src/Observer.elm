module Observer exposing
  ( Observer
  , Verdict(..)
  , isEqual
  )


type alias Observer a =
  a -> Verdict


type Verdict
  = Accept
  | Reject String


isEqual : a -> Observer a
isEqual expected actual =
  if expected == actual then
    Accept
  else
    Reject <| "Expected " ++ (toString expected) ++ " to equal " ++ (toString actual) ++ ", but it does not."


toString : a -> String
toString =
  Elm.Kernel.Debug.toString