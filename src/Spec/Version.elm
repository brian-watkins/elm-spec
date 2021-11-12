module Spec.Version exposing
  ( Version
  , core
  , isOk
  , error
  )

import Spec.Report as Report exposing (Report)


type alias Version = Int


core : Version
core = 8


isOk : { required: Version, actual: Version } -> Bool
isOk { required, actual } =
  actual == required


error : { required: Version, actual: Version } -> Report
error { required, actual } =
  Report.batch
    [ Report.fact "elm-spec requires elm-spec-core at version" <| String.fromInt required ++ ".x"
    , Report.fact "but your elm-spec-core version is" <| String.fromInt actual ++ ".x"
    , Report.note "Check your JavaScript runner and upgrade to make the versions match."
    ]