module Specs.SelectorSpec exposing (..)

import Spec exposing (Spec)
import Spec.Subject as Subject
import Spec.Scenario exposing (..)
import Spec.Html as Markup
import Spec.Html.Selector exposing (..)
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Runner


attributeNameSelectorSpec : Spec () Msg
attributeNameSelectorSpec =
  Spec.describe "an html program"
  [ scenario "Select by attribute name" (
      Subject.initWithModel ()
        |> Subject.withView testView
    )
    |> it "finds the element" (
      Markup.select << by [ attributeName "data-fun" ]
        |> Markup.expectElement (Markup.hasText "This is fun!")
    )
  ]


onlyOneTagAllowedSpec : Spec () Msg
onlyOneTagAllowedSpec =
  Spec.describe "an html program"
  [ scenario "Select by multiple tags" (
      Subject.initWithModel ()
        |> Subject.withView testView
    )
    |> it "uses the first tag only" (
      Markup.select << by [ tag "h1", tag "div", tag "a" ]
        |> Markup.expectElement (Markup.hasText "This is an H1 tag")
    )
  ]


tagSelectorSpec : Spec () Msg
tagSelectorSpec =
  Spec.describe "an html program"
  [ scenario "Selects elements by tag" (
      Subject.initWithModel ()
        |> Subject.withView testView
    )
    |> it "renders the text on the view" (
      Markup.select << by [ tag "h1" ]
        |> Markup.expectElement (Markup.hasText "This is an H1 tag")
    )
  ]


combinedTagSelectorSpec : Spec () Msg
combinedTagSelectorSpec =
  Spec.describe "an html program"
  [ scenario "Selects by tag and then id" (
      Subject.initWithModel ()
        |> Subject.withView testView
    )
    |> it "selects the text on the view" (
      Markup.select << by [ tag "h1", attributeName "data-tag", id "fun-id" ]
        |> Markup.expectElement (Markup.hasText "This is an H1 tag")
    )
  , scenario "Selects by id and then tag" (
      Subject.initWithModel ()
        |> Subject.withView testView
    )
    |> it "selects the text on the view" (
      Markup.select << by [ id "fun-id", attributeName "data-tag", tag "h1" ]
        |> Markup.expectElement (Markup.hasText "This is an H1 tag")
    )
  ]


type Msg
  = Msg


testView : () -> Html Msg
testView _ =
  Html.div []
  [ Html.p [] []
  , Html.div []
    [ Html.h1 [ Attr.id "fun-id", Attr.attribute "data-tag" "tag" ] [ Html.text "This is an H1 tag" ]
    , Html.div [ Attr.attribute "data-fun" "something" ] [ Html.text "This is fun!" ]
    ]
  ]


selectSpec : String -> Maybe (Spec () Msg)
selectSpec name =
  case name of
    "tag" -> Just tagSelectorSpec
    "combinedTag" -> Just combinedTagSelectorSpec
    "onlyOneTag" -> Just onlyOneTagAllowedSpec
    "attributeName" -> Just attributeNameSelectorSpec
    _ -> Nothing


main =
  Runner.browserProgram selectSpec