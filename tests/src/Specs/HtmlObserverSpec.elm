module Specs.HtmlObserverSpec exposing (..)

import Spec exposing (..)
import Spec.Setup as Setup
import Spec.Markup as Markup
import Spec.Markup.Selector exposing (..)
import Spec.Observer as Observer
import Html exposing (Html)
import Html.Attributes as Attr
import Runner


hasTextSpec : Spec Model Msg
hasTextSpec =
  Spec.describe "hasText"
  [ scenario "the hasText matcher is satisfied" (
      given (
        Setup.initWithModel { activity = "running" }
          |> Setup.withView testTextView
      )
      |> it "matches the text" (
        Markup.observeElement
          |> Markup.query << by [ id "my-activity" ]
          |> expect (Markup.hasText "My activity is: running!")
      )
    )
  , scenario "the hasText matcher fails" (
      given (
        Setup.initWithModel { activity = "Running" }
          |> Setup.withView testTextView
      )
      |> it "renders the name based on the model" (
        Markup.observeElement
          |> Markup.query << by [ id "my-activity" ]
          |> expect (Markup.hasText "Something not present")
      )
    )
  ]


hasTextContainedSpec : Spec Model Msg
hasTextContainedSpec =
  Spec.describe "hasText"
  [ scenario "the hasText matcher is satisfied" (
      given (
        Setup.initWithModel { activity = "swimming" }
          |> Setup.withView testTextView
      )
      |> it "matches the text" (
        Markup.observeElement
          |> Markup.query << by [ id "things" ]
          |> expect (Markup.hasText "swimming")
      )
    )
  ]


testTextView : Model -> Html Msg
testTextView model =
  Html.div []
  [ Html.div [ Attr.id "my-activity" ] [ Html.text <| "My activity is: " ++ model.activity ++ "!" ]
  , Html.ol [ Attr.id "things" ]
    [ Html.li [] [ Html.text "bowling" ]
    , Html.li [] [ Html.text model.activity ]
    , Html.li [] [ Html.text "walking" ]
    ]
  ]


hasAttributeSpec : Spec Model Msg
hasAttributeSpec =
  Spec.describe "hasAttribute"
  [ scenario "when the element has the attribute with the right value" (
      given (
        Setup.initWithModel { activity = "bowling" }
          |> Setup.withView testAttributeView
      )
      |> it "sets the attribute value based on the model" (
        Markup.observeElement
          |> Markup.query << by [ id "activity" ]
          |> expect (Markup.hasAttribute ("data-fun-activity", "bowling"))
      )
    )
  , scenario "when the element does not have the expected attribute" (
      given (
        Setup.initWithModel { activity = "bowling" }
          |> Setup.withView testAttributeView
      )
      |> it "sets the attribute value based on the model" (
        Markup.observeElement
          |> Markup.query << by [ id "activity" ]
          |> expect (Markup.hasAttribute ("data-unknown-attribute", "bowling"))
      )
    )
  , scenario "when the element has the attribute with the wrong value" (
      given (
        Setup.initWithModel { activity = "bowling" }
          |> Setup.withView testAttributeView
      )
      |> it "sets the attribute value based on the model" (
        Markup.observeElement
          |> Markup.query << by [ id "activity" ]
          |> expect (Markup.hasAttribute ("data-fun-activity", "running"))
      )
    )
  , scenario "when the element has no attributes" (
      given (
        Setup.initWithModel { activity = "bowling" }
          |> Setup.withView testAttributeView
      )
      |> it "sets the attribute value based on the model" (
        Markup.observeElement
          |> Markup.query << by [ tag "h1" ]
          |> expect (Markup.hasAttribute ("data-fun-activity", "running"))
      )
    )
  ]


type alias Model =
  { activity: String
  }


type Msg
  = Msg


testAttributeView : Model -> Html Msg
testAttributeView model =
  Html.div []
  [ Html.div [ Attr.id "activity", Attr.attribute "data-fun-activity" model.activity ]
    [ Html.text "Fun!" ]
  , Html.h1 [] [ Html.text "something" ]
  ]


selectSpec : String -> Maybe (Spec Model Msg)
selectSpec name =
  case name of
    "hasText" -> Just hasTextSpec
    "hasTextContained" -> Just hasTextContainedSpec
    "hasAttribute" -> Just hasAttributeSpec
    _ -> Nothing


main =
  Runner.browserProgram selectSpec