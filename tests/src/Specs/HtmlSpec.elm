port module Specs.HtmlSpec exposing (..)

import Spec exposing (Spec)
import Spec.Subject as Subject
import Spec.Scenario exposing (..)
import Spec.Markup as Markup
import Spec.Observer as Observer
import Spec.Markup.Selector exposing (..)
import Spec.Markup.Event as Event
import Spec.Port as Port
import Spec.Claim as Claim
import Spec.Observation.Report as Report
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Runner
import Json.Encode as Encode
import Specs.Helpers exposing (..)


htmlSpecSingle : Spec Model Msg
htmlSpecSingle =
  Spec.describe "an html program"
  [ scenario "observes the rendered view" (
      given (
        Subject.initWithModel { name = "Cool Dude", count = 78 }
          |> Subject.withView testView
      )
      |> observeThat
        [ it "renders the name based on the model" (
            Markup.observeElement
              |> Markup.query << by [ id "my-name" ]
              |> expect (Markup.hasText "Hello, Cool Dude!")
          )
        , it "does not find an element that is not there" (
            Markup.observeElement
              |> Markup.query << by [ id "something-not-present" ]
              |> expect (Markup.hasText "Hello, Cool Dude!")
          )
        ]
    )
  ]


htmlSpecMultiple : Spec Model Msg
htmlSpecMultiple =
  Spec.describe "an html program"
  [ scenario "multiple observations one" (
      given (
        Subject.initWithModel { name = "Cool Dude", count = 78 }
          |> Subject.withView testView
      )
      |> observeThat
        [ it "renders the name based on the model" (
            Markup.observeElement
              |> Markup.query << by [ id "my-name" ]
              |> expect (Markup.hasText "Hello, Cool Dude!")
          )
        , it "renders the count based on the model" (
            Markup.observeElement
              |> Markup.query << by [ id "my-count" ]
              |> expect (Markup.hasText "The count is 78!")
          )
        ]
    )
  , scenario "multiple observations two" (
      given (
        Subject.initWithModel { name = "Cool Dude", count = 78 }
          |> Subject.withView testView
      )
      |> observeThat
        [ it "finds a third thing" (
            Markup.observeElement
              |> Markup.query << by [ id "my-label" ]
              |> expect (Markup.hasText "Here is a label")
          )
        , it "finds a fourth thing" (
            Markup.observeElement
              |> Markup.query << by [ id "my-label-2" ]
              |> expect (Markup.hasText "Another label")
          )
        ]
    )
  ]


targetUnknownSpec : Spec Model Msg
targetUnknownSpec =
  Spec.describe "an html program"
  [ scenario "targeting an unknown element" (
      given (
        Subject.initWithModel { name = "Cool Dude", count = 0 }
          |> Subject.withUpdate testUpdate
          |> Subject.withView testView
      )
      |> when "the button is clicked three times"
        [ Markup.target << by [ id "some-element-that-does-not-exist" ]
        , Event.click
        , Event.click
        , Event.click
        ]
      |> when "the other button is clicked once"
        [ Markup.target << by [ id "another-button" ]
        , Event.click
        ]
      |> it "renders the count" (
        Markup.observeElement
          |> Markup.query << by [ id "my-count" ]
          |> expect (Markup.hasText "The count is 30!")
      )
    )
  , scenario "Should not run since the spec has been aborted" (
      given (
        Subject.initWithModel { name = "Cool Dude", count = 0 }
          |> Subject.withUpdate testUpdate
          |> Subject.withView testView
      )
      |> it "should not do this since we've failed already" (
          Markup.observeElement
            |> Markup.query << by [ id "my-name" ]
            |> expect (Markup.hasText "Hello, Somebody!")
      )
    )
  ]


subSpec : Spec Model Msg
subSpec =
  Spec.describe "an html program"
  [ scenario "Program with a subscription" (
      given (
        Subject.initWithModel { name = "Cool Dude", count = 0 }
          |> Subject.withUpdate testSubUpdate
          |> Subject.withView testSubView
          |> Subject.withSubscriptions testSubscriptions
      )
      |> when "a subscription message is received"
        [ Port.send "htmlSpecSub" <| Encode.int 27
        , Port.send "htmlSpecSub" <| Encode.int 13
        ]
      |> observeThat
        [ it "renders the count" (
            Markup.observeElement
              |> Markup.query << by [ id "my-count" ]
              |> expect (Markup.hasText "The count is 40!")
          )
        , it "updates the model" (
            Observer.observeModel .count
              |> expect (equals 40)
          )
        ]
    )
  ]


manyElementsSpec : Spec Model Msg
manyElementsSpec =
  Spec.describe "an html program"
  [ scenario "the view has many elements" (
      given (
        Subject.initWithModel { name = "Cool Dude", count = 7 }
          |> Subject.withUpdate testUpdate
          |> Subject.withView testView
      )
      |> observeThat
        [ it "selects many elements" (
            Markup.observeElements
              |> Markup.query << by [ tag "div" ]
              |> expect (Claim.isListWithLength 6)
          )
        , it "fetchs text for the elements" (
            Markup.observeElements
              |> Markup.query << by [ tag "div" ]
              |> expect (\elements ->
                List.drop 2 elements
                  |> List.head
                  |> Maybe.map (Markup.hasText "The count is 7!")
                  |> Maybe.withDefault (Claim.Reject <| Report.note "Element not found!")
              )
          )
        ]
    )
  ]


observePresenceSpec : Spec Model Msg
observePresenceSpec =
  Spec.describe "observe presence"
  [ scenario "nothing is expected to be found" (
      given (
        Subject.initWithModel { name = "Cool Dude", count = 7 }
          |> Subject.withView testView
      )
      |> it "selects nothing" (
        Markup.observe
          |> Markup.query << by [ id "nothing" ]
          |> expect Claim.isNothing
      )
    )
  , scenario "nothing is expected but something is found" (
      given (
        Subject.initWithModel { name = "Cool Dude", count = 7 }
          |> Subject.withView testView
      )
      |> it "selects nothing" (
        Markup.observe
          |> Markup.query << by [ id "my-name" ]
          |> expect Claim.isNothing
      )
    )
  , scenario "something is expected and something is found" (
      given (
        Subject.initWithModel { name = "Cool Dude", count = 7 }
          |> Subject.withView testView
      )
      |> it "selects nothing" (
        Markup.observe
          |> Markup.query << by [ id "my-name" ]
          |> expect Claim.isSomething
      )
    )
  , scenario "something is expected but nothing is found" (
      given (
        Subject.initWithModel { name = "Cool Dude", count = 7 }
          |> Subject.withView testView
      )
      |> it "selects nothing" (
        Markup.observe
          |> Markup.query << by [ id "nothing" ]
          |> expect Claim.isSomething
      )
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
    "sub" -> Just subSpec
    "targetUnknown" -> Just targetUnknownSpec
    "manyElements" -> Just manyElementsSpec
    "observePresence" -> Just observePresenceSpec
    _ -> Nothing


main =
  Runner.browserProgram selectSpec