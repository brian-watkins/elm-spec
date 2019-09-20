module Specs.HtmlObserverSpec exposing (..)

import Spec exposing (Spec)
import Spec.Subject as Subject
import Spec.Scenario exposing (..)
import Spec.Html as Markup
import Spec.Html.Selector exposing (..)
import Html exposing (Html)
import Html.Attributes as Attr
import Runner


hasAttributeSpec : Spec Model Msg
hasAttributeSpec =
  Spec.describe "hasAttribute"
  [ scenario "when the element has the attribute with the right value" (
      Subject.initWithModel { activity = "bowling" }
        |> Subject.withView testAttributeView
    )
    |> it "sets the attribute value based on the model" (
      Markup.select << by [ id "activity" ]
        |> Markup.expectElement (Markup.hasAttribute ("data-fun-activity", "bowling"))
    )
  , scenario "when the element does not have the expected attribute" (
      Subject.initWithModel { activity = "bowling" }
        |> Subject.withView testAttributeView
    )
    |> it "sets the attribute value based on the model" (
      Markup.select << by [ id "activity" ]
        |> Markup.expectElement (Markup.hasAttribute ("data-unknown-attribute", "bowling"))
    )
  , scenario "when the element has the attribute with the wrong value" (
      Subject.initWithModel { activity = "bowling" }
        |> Subject.withView testAttributeView
    )
    |> it "sets the attribute value based on the model" (
      Markup.select << by [ id "activity" ]
        |> Markup.expectElement (Markup.hasAttribute ("data-fun-activity", "running"))
    )
  , scenario "when the element has no attributes" (
      Subject.initWithModel { activity = "bowling" }
        |> Subject.withView testAttributeView
    )
    |> it "sets the attribute value based on the model" (
      Markup.select << by [ tag "h1" ]
        |> Markup.expectElement (Markup.hasAttribute ("data-fun-activity", "running"))
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
    "hasAttribute" -> Just hasAttributeSpec
    _ -> Nothing


main =
  Runner.browserProgram selectSpec