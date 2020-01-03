module Specs.HtmlObserverSpec exposing (..)

import Spec exposing (..)
import Spec.Setup as Setup
import Spec.Markup as Markup
import Spec.Markup.Selector exposing (..)
import Spec.Observer as Observer
import Spec.Claim exposing (..)
import Specs.Helpers exposing (equals)
import Html exposing (Html)
import Html.Attributes as Attr
import Json.Decode as Json
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


attributeSpec : Spec Model Msg
attributeSpec =
  Spec.describe "attribute"
  [ scenario "the attribute value satisfies the claim" (
      given (
        Setup.initWithModel { activity = "bowling" }
          |> Setup.withView testAttributeView
      )
      |> it "finds the attribute for a claim" (
        Markup.observeElement
          |> Markup.query << by [ id "activity" ]
          |> expect (Markup.attribute "data-fun-activity" <| isSomethingWhere <| equals "bowling")
      )
    )
  , scenario "the attribute value does not satisfy the claim" (
      given (
        Setup.initWithModel { activity = "bowling" }
          |> Setup.withView testAttributeView
      )
      |> it "finds the attribute for a claim" (
        Markup.observeElement
          |> Markup.query << by [ id "activity" ]
          |> expect (Markup.attribute "data-fun-activity" <| isSomethingWhere <| stringContains 1 "fishing")
      )
    )
  , scenario "the attribute is not found" (
      given (
        Setup.initWithModel { activity = "bowling" }
          |> Setup.withView testAttributeView
      )
      |> it "finds nothing" (
        Markup.observeElement
          |> Markup.query << by [tag "h1" ]
          |> expect (Markup.attribute "data-wrong-attribute" isNothing)
      )
    )
  ]


hasPropertySpec : Spec Model Msg
hasPropertySpec =
  Spec.describe "hasProperty"
  [ scenario "element has the property with the right value" (
      given (
        propertySpecSetup
      )
      |> it "gets the value of the property" (
        Markup.observeElement
          |> Markup.query << by [ tag "button" ]
          |> expect (Markup.property (Json.field "disabled" Json.bool) isTrue)
      )
    )
  , scenario "the element does not have the property" (
      given (
        propertySpecSetup
      )
      |> it "fails" (
        Markup.observeElement
          |> Markup.query << by [ tag "button" ]
          |> expect (Markup.property (Json.field "something_it_does_not_have" Json.bool) isTrue)
      )
    )
  , scenario "getting a property on all elements" (
      given (
        propertySpecSetup
      )
      |> it "gets the property for each element" (
        Markup.observeElements
          |> Markup.query << by [ tag "div" ]
          |> expect (isListWhere
            [ Markup.property (Json.field "id" Json.string) <| equals "root"
            , \_ -> Spec.Claim.Accept
            , Markup.property (Json.field "id" Json.string) <| equals "fun-div"
            ]
          )
      )
    )
  , scenario "crazy case" (
      given (
        propertySpecSetup
      )
      |> it "gets the value" (
        Markup.observeElement
          |> Markup.query << by [ id "root" ]
          |> expect (Markup.property nodeDecoder <| equals "fun-div")
      )
    )
  ]


nodeDecoder =
  Json.at [ "childNodes", "1", "childNodes", "0", "id" ] Json.string


propertySpecSetup =
  Setup.initWithModel { activity = "bowling" }
    |> Setup.withView testPropertyView


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


testPropertyView : Model -> Html Msg
testPropertyView model =
  Html.div [ Attr.id "root" ]
  [ Html.button [ Attr.disabled True ] [ Html.text "Click me!" ]
  , Html.div []
    [ Html.div [ Attr.id "fun-div" ] [ Html.text "FUN!" ]
    ]
  ]


selectSpec : String -> Maybe (Spec Model Msg)
selectSpec name =
  case name of
    "hasText" -> Just hasTextSpec
    "hasTextContained" -> Just hasTextContainedSpec
    "hasAttribute" -> Just hasAttributeSpec
    "attribute" -> Just attributeSpec
    "hasProperty" -> Just hasPropertySpec
    _ -> Nothing


main =
  Runner.browserProgram selectSpec