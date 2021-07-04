module Specs.HtmlObserverSpec exposing (..)

import Spec exposing (..)
import Spec.Setup as Setup
import Spec.Markup as Markup
import Spec.Markup.Selector exposing (..)
import Spec.Claim exposing (..)
import Specs.Helpers exposing (equals)
import Html exposing (Html)
import Html.Attributes as Attr
import Json.Decode as Json
import Runner


textSpec : Spec Model Msg
textSpec =
  Spec.describe "text"
  [ scenario "the text satisfies the claim" (
      given (
        Setup.initWithModel { activity = "football" }
          |> Setup.withView testTextView
      )
      |> it "applies the claim to the text" (
        Markup.observeElement
          |> Markup.query << by [ id "my-activity" ]
          |> expect (isSomethingWhere <|
            Markup.text <| equals "My activity is: football!"
          )
      )
    )
  , scenario "the claim about the text is rejected" (
      given (
        Setup.initWithModel { activity = "football" }
          |> Setup.withView testTextView
      )
      |> it "applies the claim to the text" (
        Markup.observeElement
          |> Markup.query << by [ id "my-activity" ]
          |> expect (isSomethingWhere <|
            Markup.text <| equals "football"
          )
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
          |> expect (isSomethingWhere <| 
            Markup.attribute "data-fun-activity" <| isSomethingWhere <| equals "bowling"
          )
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
          |> expect (isSomethingWhere <| 
            Markup.attribute "data-fun-activity" <| isSomethingWhere <| isStringContaining 1 "fishing"
          )
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
          |> expect (isSomethingWhere <| 
            Markup.attribute "data-wrong-attribute" isNothing
          )
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
          |> expect (isSomethingWhere <| Markup.property (Json.field "disabled" Json.bool) isTrue)
      )
    )
  , scenario "the element does not have the property" (
      given (
        propertySpecSetup
      )
      |> it "fails" (
        Markup.observeElement
          |> Markup.query << by [ tag "button" ]
          |> expect (isSomethingWhere <| Markup.property (Json.field "something_it_does_not_have" Json.bool) isTrue)
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
          |> expect (isSomethingWhere <| Markup.property nodeDecoder <| equals "fun-div")
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
testPropertyView _ =
  Html.div [ Attr.id "root" ]
  [ Html.button [ Attr.disabled True ] [ Html.text "Click me!" ]
  , Html.div []
    [ Html.div [ Attr.id "fun-div" ] [ Html.text "FUN!" ]
    ]
  ]


selectSpec : String -> Maybe (Spec Model Msg)
selectSpec name =
  case name of
    "text" -> Just textSpec
    "attribute" -> Just attributeSpec
    "hasProperty" -> Just hasPropertySpec
    _ -> Nothing


main =
  Runner.browserProgram selectSpec