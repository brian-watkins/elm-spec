module Specs.ObserverSpec exposing (main)

import Spec exposing (..)
import Spec.Setup as Setup
import Spec.Markup as Markup
import Spec.Observer as Observer
import Spec.Markup.Selector exposing (..)
import Spec.Claim as Claim
import Html exposing (Html)
import Html.Attributes as Attr
import Runner
import Specs.Helpers exposing (..)


focusSpec : Spec Model Msg
focusSpec =
  Spec.describe "focusing an observer"
  [ scenario "observing the element's text" (
      given (
        Setup.initWithModel { name = "Cool Dude" }
          |> Setup.withView testView
      )
      |> observeThat
        [ it "satisfies the claim" (
            Markup.observeElement
              |> Markup.query << by [ id "my-name" ]
              |> Observer.focus Claim.isSomethingWhere
              |> Observer.focus Markup.text
              |> expect (equals "Hello, Cool Dude!")
          )
        , it "stops when the element does not exist" (
            Markup.observeElement
              |> Markup.query << by [ id "something-not-present" ]
              |> Observer.focus Claim.isSomethingWhere
              |> Observer.focus Markup.text
              |> expect (equals "Hello, Cool Dude!")
          )
        ]
    )
  ]


type alias Model =
  { name: String
  }


type Msg
  = Msg


testView : Model -> Html Msg
testView model =
  Html.div []
  [ Html.div [ Attr.id "my-name" ] [ Html.text <| "Hello, " ++ model.name ++ "!" ]
  ]


selectSpec : String -> Maybe (Spec Model Msg)
selectSpec name =
  case name of
    "focus" -> Just focusSpec
    _ -> Nothing


main =
  Runner.browserProgram selectSpec