module Specs.StringClaimsSpec exposing (main)

import Spec exposing (..)
import Spec.Setup as Setup
import Spec.Observer as Observer
import Spec.Claim as Claim
import Runner


containsSpec : Spec Model Msg
containsSpec =
  describe "contains claim"
  [ scenario "the string does not contain the string" (
      given (
        setupWithString "blah blah blahblah apple"
      )
      |> it "does not contain the string" (
        Observer.observeModel .text
          |> expect (Claim.isStringContaining 0 "fun")
      )
    )
  , scenario "the string contains the string" (
      given (
        setupWithString "blah blah blahblah apple"
      )
      |> it "contains the string" (
        Observer.observeModel .text
          |> expect (Claim.isStringContaining 4 "blah")
      )
    )
  , scenario "the contains claim fails for multiple instances and times" (
      given (
        setupWithString "fun"
      )
      |> it "fails" (
        Observer.observeModel .text
          |> expect (Claim.isStringContaining 4 "blah")
      )
    )
  , scenario "the contains claim fails for one instance" (
      given (
        setupWithString "blah blah blahblah apple"
      )
      |> it "fails" (
        Observer.observeModel .text
          |> expect (Claim.isStringContaining 1 "blah")
      )
    )
  , scenario "the contains claim fails for one time" (
      given (
        setupWithString "blah apple"
      )
      |> it "fails" (
        Observer.observeModel .text
          |> expect (Claim.isStringContaining 0 "blah")
      )
    )
  ]


setupWithString actual =
  Setup.initWithModel { text = actual }


type alias Model =
  { text: String
  }

type Msg =
  Msg

selectSpec : String -> Maybe (Spec Model Msg)
selectSpec specName =
  case specName of
    "contains" -> Just containsSpec
    _ -> Nothing


main =
  Runner.program selectSpec