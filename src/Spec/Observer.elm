module Spec.Observer exposing
  ( Observer
  , Verdict(..)
  , isEqual
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
      

toString : a -> String
toString =
  Elm.Kernel.Debug.toString