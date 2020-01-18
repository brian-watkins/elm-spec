module Specs.SelectorSpec exposing (..)

import Spec exposing (..)
import Spec.Setup as Setup
import Spec.Markup as Markup
import Spec.Markup.Selector exposing (..)
import Spec.Observer as Observer
import Spec.Claim as Claim exposing (isListWithLength, isSomethingWhere)
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Specs.Helpers exposing (..)
import Runner


descendantsOfSpec : Spec () Msg
descendantsOfSpec =
  Spec.describe "an html program"
  [ scenario "Select descendants" (
      given (
        Setup.initWithModel ()
          |> Setup.withView descendantsView
      )
      |> it "finds all the elements" (
        Markup.observeElements
          |> Markup.query
              << descendantsOf [ id "my-part" ]
              << by [ tag "div" ]
          |> expect (isListWithLength 4)
      )
    )
  , scenario "Multiple descendants" (
      given (
        Setup.initWithModel ()
          |> Setup.withView descendantsView
      )
      |> it "finds all the elements" (
        Markup.observeElements
          |> Markup.query
              << descendantsOf [ id "my-part" ]
              << descendantsOf [ attributeName "fun" ]
              << by [ tag "div" ]
          |> expect (isListWithLength 1)
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
        Setup.initWithModel ()
          |> Setup.withView testView
      )
      |> it "finds the element" (
        Markup.observeElement
          |> Markup.query << by [ attributeName "data-fun" ]
          |> expect (isSomethingWhere <| Markup.text <| equals "This is fun!")
      )
    )
  ]


attributeSelectorSpec : Spec () Msg
attributeSelectorSpec =
  Spec.describe "attribute selector"
  [ scenario "select by attribute" (
      given (
        Setup.initWithModel ()
          |> Setup.withView testView
      )
      |> it "finds the element" (
        Markup.observeElement
          |> Markup.query << by [ attribute ("data-fun", "something fun") ]
          |> expect (isSomethingWhere <| Markup.text <| equals "This is fun!")
      )
    )
  ]


onlyOneTagAllowedSpec : Spec () Msg
onlyOneTagAllowedSpec =
  Spec.describe "an html program"
  [ scenario "Select by multiple tags" (
      given (
        Setup.initWithModel ()
          |> Setup.withView testView
      )
      |> it "uses the first tag only" (
        Markup.observeElement
          |> Markup.query << by [ tag "h1", tag "div", tag "a" ]
          |> expect (isSomethingWhere <| Markup.text <| equals "This is an H1 tag")
      )
    )
  ]


tagSelectorSpec : Spec () Msg
tagSelectorSpec =
  Spec.describe "an html program"
  [ scenario "Selects elements by tag" (
      given (
        Setup.initWithModel ()
          |> Setup.withView testView
      )
      |> it "renders the text on the view" (
        Markup.observeElement
          |> Markup.query << by [ tag "h1" ]
          |> expect (isSomethingWhere <| Markup.text <| equals "This is an H1 tag")
      )
    )
  ]


combinedTagSelectorSpec : Spec () Msg
combinedTagSelectorSpec =
  Spec.describe "an html program"
  [ scenario "Selects by tag and then id" (
      given (
        Setup.initWithModel ()
          |> Setup.withView testView
      )
      |> it "selects the text on the view" (
        Markup.observeElement
          |> Markup.query << by [ tag "h1", attributeName "data-tag", id "fun-id" ]
          |> expect (isSomethingWhere <| Markup.text <| equals "This is an H1 tag")
      )
    )
  , scenario "Selects by id and then tag" (
      given (
        Setup.initWithModel ()
          |> Setup.withView testView
      )
      |> it "selects the text on the view" (
        Markup.observeElement
          |> Markup.query << by [ id "fun-id", attributeName "data-tag", tag "h1" ]
          |> expect (isSomethingWhere <| Markup.text <| equals "This is an H1 tag")
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