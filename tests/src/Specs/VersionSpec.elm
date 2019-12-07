module Specs.VersionSpec exposing (main)

import Spec exposing (..)
import Spec.Setup as Setup
import Spec.Observer as Observer
import Specs.Helpers exposing (..)
import Runner


versionSpec : Spec () Msg
versionSpec =
  Spec.describe "version check"
  [ scenario "the version does not match" (
      given (
        Setup.initWithModel ()
      )
      |> it "does not run" (
        Observer.observeModel identity
          |> expect (equals ())
      )
    )
  ]


type Msg
  = Msg


selectSpec : String -> Maybe (Spec () Msg)
selectSpec name =
  case name of
    "version" -> Just versionSpec
    _ -> Nothing


main =
  Runner.runSuiteWithVersion 10
    [ versionSpec
    ]