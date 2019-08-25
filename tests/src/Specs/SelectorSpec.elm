module Specs.SelectorSpec exposing (..)

import Spec exposing (Spec)
import Spec.Subject as Subject
import Spec.Html as Markup
import Spec.Html.Selector exposing (..)
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Runner


onlyOneTagAllowedSpec : Spec () Msg
onlyOneTagAllowedSpec =
  Spec.given "an Html program that attempts to select by multiple tags" (
    Subject.initWithModel ()
      |> Subject.withView testView
  )
  |> Spec.it "uses the first tag only" (
    Markup.select << by [ tag "h1", tag "div", tag "a" ]
      |> Markup.expect (Markup.hasText "This is an H1 tag")
  )


tagSelectorSpec : Spec () Msg
tagSelectorSpec =
  Spec.given "an Html program that selects elements by tag" (
    Subject.initWithModel ()
      |> Subject.withView testView
  )
  |> Spec.it "renders the text on the view" (
    Markup.select << by [ tag "h1" ]
      |> Markup.expect (Markup.hasText "This is an H1 tag")
  )


combinedTagSelectorSpec : Spec () Msg
combinedTagSelectorSpec =
  Spec.given "an Html program that selects by tag and id" (
    Subject.initWithModel ()
      |> Subject.withView testView
  )
  |> Spec.it "selects the text on the view" (
    Markup.select << by [ tag "h1", id "fun-id" ]
      |> Markup.expect (Markup.hasText "This is an H1 tag")
  )
  |> Spec.suppose (
    Spec.given "an Html program that selects by id and tag"
    >> Spec.it "selects the text on the view" (
      Markup.select << by [ id "fun-id", tag "h1" ]
        |> Markup.expect (Markup.hasText "This is an H1 tag")
    )
  )


type Msg
  = Msg


testView : () -> Html Msg
testView _ =
  Html.div []
  [ Html.p [] []
  , Html.div []
    [ Html.h1 [ Attr.id "fun-id" ] [ Html.text "This is an H1 tag" ] ]
  ]


selectSpec : String -> Maybe (Spec () Msg)
selectSpec name =
  case name of
    "tag" -> Just tagSelectorSpec
    "combinedTag" -> Just combinedTagSelectorSpec
    "onlyOneTag" -> Just onlyOneTagAllowedSpec
    _ -> Nothing


main =
  Runner.browserProgram selectSpec