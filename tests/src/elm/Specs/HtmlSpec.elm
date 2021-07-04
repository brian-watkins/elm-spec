port module Specs.HtmlSpec exposing (..)

import Spec exposing (..)
import Spec.Setup as Setup
import Spec.Markup as Markup
import Spec.Observer as Observer
import Spec.Markup.Selector exposing (..)
import Spec.Markup.Event as Event
import Spec.Port as Port
import Spec.Claim as Claim exposing (isSomethingWhere)
import Spec.Report as Report
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
        Setup.initWithModel { name = "Cool Dude", count = 78 }
          |> Setup.withView testView
      )
      |> observeThat
        [ it "renders the name based on the model" (
            Markup.observeElement
              |> Markup.query << by [ id "my-name" ]
              |> expect (isSomethingWhere <| Markup.text <| equals "Hello, Cool Dude!")
          )
        , it "does not find an element that is not there" (
            Markup.observeElement
              |> Markup.query << by [ id "something-not-present" ]
              |> expect (isSomethingWhere <| Markup.text <| equals "Hello, Cool Dude!")
          )
        ]
    )
  ]


htmlSpecMultiple : Spec Model Msg
htmlSpecMultiple =
  Spec.describe "an html program"
  [ scenario "multiple observations one" (
      given (
        Setup.initWithModel { name = "Cool Dude", count = 78 }
          |> Setup.withView testView
      )
      |> observeThat
        [ it "renders the name based on the model" (
            Markup.observeElement
              |> Markup.query << by [ id "my-name" ]
              |> expect (isSomethingWhere <| Markup.text <| equals "Hello, Cool Dude!")
          )
        , it "renders the count based on the model" (
            Markup.observeElement
              |> Markup.query << by [ id "my-count" ]
              |> expect (isSomethingWhere <| Markup.text <| equals "The count is 78!")
          )
        ]
    )
  , scenario "multiple observations two" (
      given (
        Setup.initWithModel { name = "Cool Dude", count = 78 }
          |> Setup.withView testView
      )
      |> observeThat
        [ it "finds a third thing" (
            Markup.observeElement
              |> Markup.query << by [ id "my-label" ]
              |> expect (isSomethingWhere <| Markup.text <| equals "Here is a label")
          )
        , it "finds a fourth thing" (
            Markup.observeElement
              |> Markup.query << by [ id "my-label-2" ]
              |> expect (isSomethingWhere <| Markup.text <| equals "Another label")
          )
        ]
    )
  ]


targetUnknownSpec : Spec Model Msg
targetUnknownSpec =
  Spec.describe "an html program"
  [ scenario "targeting an unknown element" (
      given (
        Setup.initWithModel { name = "Cool Dude", count = 0 }
          |> Setup.withUpdate testUpdate
          |> Setup.withView testView
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
      |> it "should fail before this" (
        Observer.observeModel (always False)
          |> expect (\_ -> Claim.Reject <| Report.note "Should not fail here!")
      )
    )
  , scenario "Should run even though previous spec was rejected" (
      given (
        Setup.initWithModel { name = "Cool Dude", count = 0 }
          |> Setup.withUpdate testUpdate
          |> Setup.withView testView
      )
      |> it "should pass" (
          Markup.observeElement
            |> Markup.query << by [ id "my-name" ]
            |> expect (isSomethingWhere <| Markup.text <| equals "Hello, Cool Dude!")
      )
    )
  ]


subSpec : Spec Model Msg
subSpec =
  Spec.describe "an html program"
  [ scenario "Program with a subscription" (
      given (
        Setup.initWithModel { name = "Cool Dude", count = 0 }
          |> Setup.withUpdate testSubUpdate
          |> Setup.withView testSubView
          |> Setup.withSubscriptions testSubscriptions
      )
      |> when "a subscription message is received"
        [ Port.send "htmlSpecSub" <| Encode.int 27
        , Port.send "htmlSpecSub" <| Encode.int 13
        ]
      |> observeThat
        [ it "renders the count" (
            Markup.observeElement
              |> Markup.query << by [ id "my-count" ]
              |> expect (isSomethingWhere <| Markup.text <| equals "The count is 40!")
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
        Setup.initWithModel { name = "Cool Dude", count = 7 }
          |> Setup.withUpdate testUpdate
          |> Setup.withView testView
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
                  |> Maybe.map (Markup.text <| equals "The count is 7!")
                  |> Maybe.withDefault (Claim.Reject <| Report.note "Element not found!")
              )
          )
        , it "finds no elements" (
            Markup.observeElements
              |> Markup.query << by [ id "blah-nothing" ]
              |> expect (Claim.isListWithLength 0)
          )
        ]
    )
  ]


observePresenceSpec : Spec Model Msg
observePresenceSpec =
  Spec.describe "observe presence"
  [ scenario "nothing is expected to be found" (
      given (
        Setup.initWithModel { name = "Cool Dude", count = 7 }
          |> Setup.withView testView
      )
      |> it "selects nothing" (
        Markup.observeElement
          |> Markup.query << by [ id "nothing" ]
          |> expect Claim.isNothing
      )
    )
  , scenario "nothing is expected but something is found" (
      given (
        Setup.initWithModel { name = "Cool Dude", count = 7 }
          |> Setup.withView testView
      )
      |> it "selects nothing" (
        Markup.observeElement
          |> Markup.query << by [ id "my-name" ]
          |> expect Claim.isNothing
      )
    )
  , scenario "something is expected and something is found" (
      given (
        Setup.initWithModel { name = "Cool Dude", count = 7 }
          |> Setup.withView testView
      )
      |> it "selects nothing" (
        Markup.observeElement
          |> Markup.query << by [ id "my-name" ]
          |> expect Claim.isSomething
      )
    )
  , scenario "something is expected but nothing is found" (
      given (
        Setup.initWithModel { name = "Cool Dude", count = 7 }
          |> Setup.withView testView
      )
      |> it "selects nothing" (
        Markup.observeElement
          |> Markup.query << by [ id "nothing" ]
          |> expect Claim.isSomething
      )
    )
  ]


failingSpec : Spec Model Msg
failingSpec =
  Spec.describe "failing"
  [ scenario "a failing scenario" (
      given (
        Setup.initWithModel { name = "Cool Dude", count = 7 }
          |> Setup.withUpdate testUpdate
          |> Setup.withView testView
      )
      |> it "fails" (
        Markup.observeElement
          |> Markup.query << by [ id "my-label" ]
          |> expect (isSomethingWhere <| Markup.text <| equals "something else")
      )
    )
  , scenario "some other scenario that passes" (
      given (
        Setup.initWithModel { name = "Cool Dude", count = 7 }
          |> Setup.withUpdate testUpdate
          |> Setup.withView testView
      )
      |> it "passes" (
        Markup.observeElement
          |> Markup.query << by [ id "my-label" ]
          |> expect (isSomethingWhere <| Markup.text <| equals "Here is a label")
      )
    )
  ]


elementLinkSpec : Spec Model Msg
elementLinkSpec =
  Spec.describe "an element application with a link"
  [ scenario "clicking the link" (
      given (
        Setup.initWithModel { name = "Awesome Person", count = 0 }
          |> Setup.withUpdate testUpdate
          |> Setup.withView testAnchorView
      )
      |> when "a link is clicked"
        [ Markup.target << by [ id "same-page" ]
        , Event.click
        , Event.click
        , Event.click
        ]
      |> it "handles the clicks" (
        Markup.observeElement
          |> Markup.query << by [ id "count" ]
          |> expect (isSomethingWhere <| Markup.text <| equals "Count: 3")
      )
    )
  ]


elementInternalLinkFailureSpec : Spec Model Msg
elementInternalLinkFailureSpec =
  Spec.describe "an element application with an internal link"
  [ scenario "failure" (
      given (
        Setup.initWithModel { name = "Awesome Person", count = 0 }
          |> Setup.withUpdate testUpdate
          |> Setup.withView testAnchorView
      )
      |> it "fails" (
        Markup.observeElement
          |> Markup.query << by [ id "count" ]
          |> expect (isSomethingWhere <| Markup.text <| equals "Count: 3")
      )
    )
  ]


elementExternalLinkFailureSpec : Spec Model Msg
elementExternalLinkFailureSpec =
  Spec.describe "an element application with an external link"
  [ scenario "failure" (
      given (
        Setup.initWithModel { name = "Awesome Person", count = 0 }
          |> Setup.withUpdate testUpdate
          |> Setup.withView testExternalAnchorView
      )
      |> it "fails" (
        Markup.observeElement
          |> Markup.query << by [ id "count" ]
          |> expect (isSomethingWhere <| Markup.text <| equals "Count: 3")
      )
    )
  ]


logElementSpec : Spec Model Msg
logElementSpec =
  Spec.describe "log element"
  [ scenario "existing element" (
      given (
        Setup.initWithModel { name = "Fun Person", count = 21 }
          |> Setup.withUpdate testUpdate
          |> Setup.withView testView
      )
      |> when "an element is logged"
        [ Markup.log << by [ id "my-name" ]
        ]
      |> it "completes the spec" (
        Markup.observeElement
          |> Markup.query << by [ id "my-name" ]
          |> expect (isSomethingWhere <| Markup.text <| equals "Hello, Fun Person!")
      )
    )
  , scenario "element does not exist" (
      given (
        Setup.initWithModel { name = "Fun Person", count = 21 }
          |> Setup.withUpdate testUpdate
          |> Setup.withView testView
      )
      |> when "an unknown element is logged"
        [ Markup.log << by [ id "unknown-element" ]
        ]
      |> it "completes the spec" (
        Markup.observeElement
          |> Markup.query << by [ id "my-name" ]
          |> expect (isSomethingWhere <| Markup.text <| equals "Hello, Fun Person!")
      )
    )
  ]


testView : Model -> Html Msg
testView model =
  Html.div []
  [ Html.div [ Attr.id "my-name", Attr.class "pretty" ] [ Html.text <| "Hello, " ++ model.name ++ "!" ]
  , Html.div [ Attr.id "my-count" ] [ Html.text <| "The count is " ++ String.fromInt model.count ++ "!" ]
  , Html.div []
    [ Html.div [ Attr.id "my-label" ] [ Html.text "Here is a label" ]
    , Html.div [ Attr.id "my-label-2" ] [ Html.text "Another label" ]
    ]
  , Html.button [ Attr.id "my-button", Events.onClick HandleClick ] [ Html.text "Click me!" ]
  , Html.button [ Attr.id "another-button", Events.onClick HandleMegaClick ] [ Html.text "Click me!" ]
  ]


testAnchorView : Model -> Html Msg
testAnchorView model =
  Html.div []
  [ Html.a [ Attr.id "same-page", Attr.href "#", Events.onClick HandleClick ] [ Html.text "Click ms!" ]
  , Html.a [ Attr.id "another-page", Attr.href "/some-other-page" ] [ Html.text "I go to another page!" ]
  , Html.div [ Attr.id "count" ] [ Html.text <| "Count: " ++ String.fromInt model.count ]
  ]


testExternalAnchorView : Model -> Html Msg
testExternalAnchorView model =
  Html.div []
  [ Html.a [ Attr.id "another-page", Attr.href "http://my-cool-site.com" ] [ Html.text "I go to another page!" ]
  , Html.div [ Attr.id "count" ] [ Html.text <| "Count: " ++ String.fromInt model.count ]
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
testSubscriptions _ =
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
    "failing" -> Just failingSpec
    "elementLink" -> Just elementLinkSpec
    "elementInternalLinkFailure" -> Just elementInternalLinkFailureSpec
    "elementExternalLinkFailure" -> Just elementExternalLinkFailureSpec
    "logElement" -> Just logElementSpec
    _ -> Nothing


main =
  Runner.browserProgram selectSpec