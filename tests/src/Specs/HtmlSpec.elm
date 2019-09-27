port module Specs.HtmlSpec exposing (..)

import Spec exposing (Spec)
import Spec.Subject as Subject
import Spec.Scenario exposing (..)
import Spec.Markup as Markup
import Spec.Observation as Observation
import Spec.Markup.Selector exposing (..)
import Spec.Markup.Event as Event
import Spec.Port as Port
import Spec.Observer as Observer
import Spec.Observation.Report as Report
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Runner
import Json.Encode as Encode


htmlSpecSingle : Spec Model Msg
htmlSpecSingle =
  Spec.describe "an html program"
  [ scenario "observes the rendered view" (
      Subject.initWithModel { name = "Cool Dude", count = 78 }
        |> Subject.withView testView
    )
    |> it "renders the name based on the model" (
      select << by [ id "my-name" ]
        |> Markup.expectElement (Markup.hasText "Hello, Cool Dude!")
    )
    |> it "does not find an element that is not there" (
      select << by [ id "something-not-present" ]
        |> Markup.expectElement (Markup.hasText "I should not be present!")
    )
  ]


htmlSpecMultiple : Spec Model Msg
htmlSpecMultiple =
  Spec.describe "an html program"
  [ scenario "multiple observations one" (
      Subject.initWithModel { name = "Cool Dude", count = 78 }
        |> Subject.withView testView
    )
    |> it "renders the name based on the model" (
      select << by [ id "my-name" ]
        |> Markup.expectElement (Markup.hasText "Hello, Cool Dude!")
    )
    |> it "renders the count based on the model" (
      select << by [ id "my-count" ]
        |> Markup.expectElement (Markup.hasText "The count is 78!")
    )
  , scenario "multiple observations two" (
      Subject.initWithModel { name = "Cool Dude", count = 78 }
        |> Subject.withView testView
    )
    |> it "finds a third thing" (
        select << by [ id "my-label" ]
          |> Markup.expectElement (Markup.hasText "Here is a label")
      )
    |> it "finds a fourth thing" (
        select << by [ id "my-label-2" ]
          |> Markup.expectElement (Markup.hasText "Another label")
      )
  ]


clickSpec : Spec Model Msg
clickSpec =
  Spec.describe "an html program"
  [ scenario "a click event" (
      Subject.initWithModel { name = "Cool Dude", count = 0 }
        |> Subject.withUpdate testUpdate
        |> Subject.withView testView
    )
    |> when "the button is clicked three times"
      [ target << by [ id "my-button" ]
      , Event.click
      , Event.click
      , Event.click
      ]
    |> when "the other button is clicked once"
      [ target << by [ id "another-button" ]
      , Event.click
      ]
    |> it "renders the count" (
      select << by [ id "my-count" ]
        |> Markup.expectElement (Markup.hasText "The count is 30!")
    )
  ]


targetUnknownSpec : Spec Model Msg
targetUnknownSpec =
  Spec.describe "an html program"
  [ scenario "targeting an unknown element" (
      Subject.initWithModel { name = "Cool Dude", count = 0 }
        |> Subject.withUpdate testUpdate
        |> Subject.withView testView
    )
    |> when "the button is clicked three times"
      [ target << by [ id "some-element-that-does-not-exist" ]
      , Event.click
      , Event.click
      , Event.click
      ]
    |> when "the other button is clicked once"
      [ target << by [ id "another-button" ]
      , Event.click
      ]
    |> it "renders the count" (
      select << by [ id "my-count" ]
        |> Markup.expectElement (Markup.hasText "The count is 30!")
    )
  , scenario "Should not run since the spec has been aborted" (
      Subject.initWithModel { name = "Cool Dude", count = 0 }
        |> Subject.withUpdate testUpdate
        |> Subject.withView testView
    )
    |> it "should not do this since we've failed already" (
        select << by [ id "my-name" ]
          |> Markup.expectElement (Markup.hasText "Hello, Somebody!")
    )
  ]


subSpec : Spec Model Msg
subSpec =
  Spec.describe "an html program"
  [ scenario "Program with a subscription" (
    Subject.initWithModel { name = "Cool Dude", count = 0 }
        |> Subject.withUpdate testSubUpdate
        |> Subject.withView testSubView
        |> Subject.withSubscriptions testSubscriptions
    )
    |> when "a subscription message is received"
      [ Port.send "htmlSpecSub" <| Encode.int 27
      , Port.send "htmlSpecSub" <| Encode.int 13
      ]
    |> it "renders the count" (
      select << by [ id "my-count" ]
        |> Markup.expectElement (Markup.hasText "The count is 40!")
    )
    |> it "updates the model" (
      Observation.selectModel
        |> Observation.mapSelection .count
        |> Observation.expect (Observer.isEqual 40)
    )
  ]


manyElementsSpec : Spec Model Msg
manyElementsSpec =
  Spec.describe "an html program"
  [ scenario "the view has many elements" (
      Subject.initWithModel { name = "Cool Dude", count = 7 }
        |> Subject.withUpdate testUpdate
        |> Subject.withView testView
    )
    |> it "selects many elements" (
      select << by [ tag "div" ]
        |> Markup.expectElements (\elements ->
          Observer.isEqual 6 (List.length elements)
        )
    )
    |> it "fetchs text for the elements" (
      select << by [ tag "div" ]
        |> Markup.expectElements (\elements ->
          List.drop 2 elements
            |> List.head
            |> Maybe.map (Markup.hasText "The count is 7!")
            |> Maybe.withDefault (Observer.Reject <| Report.note "Element not found!")
        )
    )
  ]


expectAbsentSpec : Spec Model Msg
expectAbsentSpec =
  Spec.describe "expectAbsent"
  [ scenario "nothing is selected" (
      Subject.initWithModel { name = "Cool Dude", count = 7 }
        |> Subject.withView testView
    )
    |> it "selects nothing" (
      select << by [ id "nothing" ]
        |> Markup.expectAbsent
    )
  , scenario "something is selected" (
      Subject.initWithModel { name = "Cool Dude", count = 7 }
        |> Subject.withView testView
    )
    |> it "selects nothing" (
      select << by [ id "my-name" ]
        |> Markup.expectAbsent
    )
  ]


testView : Model -> Html Msg
testView model =
  Html.div []
  [ Html.div [ Attr.id "my-name" ] [ Html.text <| "Hello, " ++ model.name ++ "!" ]
  , Html.div [ Attr.id "my-count" ] [ Html.text <| "The count is " ++ String.fromInt model.count ++ "!" ]
  , Html.div []
    [ Html.div [ Attr.id "my-label" ] [ Html.text "Here is a label" ]
    , Html.div [ Attr.id "my-label-2" ] [ Html.text "Another label" ]
    ]
  , Html.button [ Attr.id "my-button", Events.onClick HandleClick ] [ Html.text "Click me!" ]
  , Html.button [ Attr.id "another-button", Events.onClick HandleMegaClick ] [ Html.text "Click me!" ]
  ]


type Msg
  = HandleClick
  | HandleMegaClick
  | ReceivedNumber Int


type alias Model =
  { name: String
  , count: Int
  }


testUpdate : Msg -> Model -> (Model, Cmd Msg)
testUpdate msg model =
  case msg of
    HandleClick ->
      ( { model | count = model.count + 1 }, Cmd.none )
    HandleMegaClick ->
      ( { model | count = model.count * 10 }, Cmd.none )
    _ ->
      ( model, Cmd.none )


testSubUpdate : Msg -> Model -> (Model, Cmd Msg)
testSubUpdate msg model =
  case msg of
    ReceivedNumber number ->
      ( { model | count = model.count + number }, Cmd.none )
    _ ->
      ( model, Cmd.none )


testSubView : Model -> Html Msg
testSubView model =
  Html.div []
  [ Html.div [ Attr.id "my-count" ] [ Html.text <| "The count is " ++ String.fromInt model.count ++ "!" ]
  ]


testSubscriptions : Model -> Sub Msg
testSubscriptions model =
  htmlSpecSub ReceivedNumber


port htmlSpecSub : (Int -> msg) -> Sub msg


selectSpec : String -> Maybe (Spec Model Msg)
selectSpec name =
  case name of
    "single" -> Just htmlSpecSingle
    "multiple" -> Just htmlSpecMultiple
    "click" -> Just clickSpec
    "sub" -> Just subSpec
    "targetUnknown" -> Just targetUnknownSpec
    "manyElements" -> Just manyElementsSpec
    "expectAbsent" -> Just expectAbsentSpec
    _ -> Nothing


main =
  Runner.browserProgram selectSpec