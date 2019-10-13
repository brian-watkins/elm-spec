module Specs.SelectorSpec exposing (..)

import Spec exposing (Spec)
import Spec.Subject as Subject
import Spec.Scenario exposing (..)
import Spec.Markup as Markup
import Spec.Markup.Selector exposing (..)
import Spec.Observer as Observer
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Runner


descendantsOfSpec : Spec () Msg
descendantsOfSpec =
  Spec.describe "an html program"
  [ scenario "Select descendants" (
      given (
        Subject.initWithModel ()
          |> Subject.withView descendantsView
      )
      |> it "finds all the elements" (
        select
          << descendantsOf [ id "my-part" ]
          << by [ tag "div" ]
          |> Markup.expectElements (\elements ->
            List.length elements
              |> Observer.isEqual 4
          )
      )
    )
  , scenario "Multiple descendants" (
      given (
        Subject.initWithModel ()
          |> Subject.withView descendantsView
      )
      |> it "finds all the elements" (
        select
          << descendantsOf [ id "my-part" ]
          << descendantsOf [ attributeName "fun" ]
          << by [ tag "div" ]
          |> Markup.expectElements (\elements ->
            List.length elements
              |> Observer.isEqual 1
          )
      )
    )
  ]


descendantsView : () -> Html Msg
descendantsView _ =
  Html.div []
  [ Html.div [ Attr.attribute "fun" "things" ]
    [ Html.div [] [ Html.text "Fun things" ]
    ]
  , Html.div [ Attr.id "my-part" ]
    [ Html.p [] [ Html.text "Yo!" ]
    , Html.div []
      [ Html.div [] [ Html.text "Hey!" ]
      , Html.div [ Attr.attribute "fun" "stuff" ]
        [ Html.div [] [ Html.text "FUN!" ]
        ]
      ]
    ]
  ]


attributeNameSelectorSpec : Spec () Msg
attributeNameSelectorSpec =
  Spec.describe "an html program"
  [ scenario "Select by attribute name" (
      given (
        Subject.initWithModel ()
          |> Subject.withView testView
      )
      |> it "finds the element" (
        select << by [ attributeName "data-fun" ]
          |> Markup.expectElement (Markup.hasText "This is fun!")
      )
    )
  ]


attributeSelectorSpec : Spec () Msg
attributeSelectorSpec =
  Spec.describe "attribute selector"
  [ scenario "select by attribute" (
      given (
        Subject.initWithModel ()
          |> Subject.withView testView
      )
      |> it "finds the element" (
        select << by [ attribute ("data-fun", "something fun") ]
          |> Markup.expectElement (Markup.hasText "This is fun!")
      )
    )
  ]


onlyOneTagAllowedSpec : Spec () Msg
onlyOneTagAllowedSpec =
  Spec.describe "an html program"
  [ scenario "Select by multiple tags" (
      given (
        Subject.initWithModel ()
          |> Subject.withView testView
      )
      |> it "uses the first tag only" (
        select << by [ tag "h1", tag "div", tag "a" ]
          |> Markup.expectElement (Markup.hasText "This is an H1 tag")
      )
    )
  ]


tagSelectorSpec : Spec () Msg
tagSelectorSpec =
  Spec.describe "an html program"
  [ scenario "Selects elements by tag" (
      given (
        Subject.initWithModel ()
          |> Subject.withView testView
      )
      |> it "renders the text on the view" (
        select << by [ tag "h1" ]
          |> Markup.expectElement (Markup.hasText "This is an H1 tag")
      )
    )
  ]


combinedTagSelectorSpec : Spec () Msg
combinedTagSelectorSpec =
  Spec.describe "an html program"
  [ scenario "Selects by tag and then id" (
      given (
        Subject.initWithModel ()
          |> Subject.withView testView
      )
      |> it "selects the text on the view" (
        select << by [ tag "h1", attributeName "data-tag", id "fun-id" ]
          |> Markup.expectElement (Markup.hasText "This is an H1 tag")
      )
    )
  , scenario "Selects by id and then tag" (
      given (
        Subject.initWithModel ()
          |> Subject.withView testView
      )
      |> it "selects the text on the view" (
        select << by [ id "fun-id", attributeName "data-tag", tag "h1" ]
          |> Markup.expectElement (Markup.hasText "This is an H1 tag")
      )
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
    , Html.div [ Attr.attribute "data-fun" "something fun" ] [ Html.text "This is fun!" ]
    ]
  ]


selectSpec : String -> Maybe (Spec () Msg)
selectSpec name =
  case name of
    "tag" -> Just tagSelectorSpec
    "combinedTag" -> Just combinedTagSelectorSpec
    "onlyOneTag" -> Just onlyOneTagAllowedSpec
    "attributeName" -> Just attributeNameSelectorSpec
    "attribute" -> Just attributeSelectorSpec
    "descendants" -> Just descendantsOfSpec
    _ -> Nothing


main =
  Runner.browserProgram selectSpec