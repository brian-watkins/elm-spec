module Specs.FormSpec exposing (main)

import Spec exposing (Spec)
import Spec.Subject as Subject
import Spec.Scenario exposing (..)
import Spec.Markup as Markup
import Spec.Markup.Event as Event
import Spec.Markup.Selector exposing (..)
import Spec.Observer as Observer
import Specs.Helpers exposing (equals)
import Runner
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events


checkSpec : Spec Model Msg
checkSpec =
  Spec.describe "checkboxes"
  [ scenario "the checkbox is checked" (
      given (
        testSubject
      )
      |> when "a box is checked"
        [ Markup.target << by [ id "my-checkbox" ]
        , Event.toggle
        ]
      |> it "updates the view" (
        Markup.observeElement
          |> Markup.query << by [ id "checkbox-indicator" ]
          |> expect (Markup.hasText "the box is checked")
      )
    )
  , scenario "the box is checked multiple times" (
      given (
        testSubject
      )
      |> when "a box is checked multiple times"
        [ Markup.target << by [ id "my-checkbox" ]
        , Event.toggle
        , Event.toggle
        , Event.toggle
        ]
      |> it "toggles the checked property" (
        Observer.observeModel .checks
          |> expect (equals [ True, False, True ])
      )
    )
  , scenario "no element targeted to check" (
      given (
        testSubject
      )
      |> when "a check occurs without targeting an element"
        [ Event.toggle
        ]
      |> it "fails" (
        Markup.observeElement
          |> Markup.query << by [ id "checkbox-indicator" ]
          |> expect (Markup.hasText "the box is checked")
      )
    )
  ]


inputSpec : Spec Model Msg
inputSpec =
  Spec.describe "an html program"
  [ scenario "Input event" (
      given (
        testSubject
      )
      |> when "some text is input"
        [ Markup.target << by [ id "my-field" ]
        , Event.input "Here is some fun text!"
        ]
      |> it "renders the text on the view" (
        Markup.observeElement
          |> Markup.query << by [ id "my-message" ]
          |> expect (Markup.hasText "You wrote: Here is some fun text!")
      )
    )
  , scenario "no element targeted for input" (
      given (
        testSubject
      )
      |> when "some text is input without targeting an element"
        [ Event.input "Here is some fun text!"
        ]
      |> it "fails" (
        Markup.observeElement
          |> Markup.query << by [ id "my-message" ]
          |> expect (Markup.hasText "You wrote: Here is some fun text!")
      )
    )
  ]

testSubject =
  Subject.initWithModel { checks = [], checked = False, message = "" }
    |> Subject.withView testView
    |> Subject.withUpdate testUpdate


type alias Model =
  { checked: Bool
  , checks: List Bool
  , message: String
  }


type Msg
  = GotText String
  | Checked Bool


testView : Model -> Html Msg
testView model =
  Html.form []
  [ Html.input [ Attr.id "my-field", Events.onInput GotText ] []
  , Html.input [ Attr.id "my-checkbox", Attr.type_ "checkbox", Attr.checked model.checked, Events.onCheck Checked ]
    [ Html.text "Check me, please!" ]
  , Html.hr [] []
  , Html.div [ Attr.id "my-message" ] [ Html.text <| "You wrote: " ++ model.message ]
  , Html.div [ Attr.id "checkbox-indicator" ]
    [ if model.checked then
        Html.text "the box is checked"
      else
        Html.text "not checked"
    ]
  ]


testUpdate : Msg -> Model -> (Model, Cmd Msg)
testUpdate msg model =
  case msg of
    GotText text ->
      ( { model | message = text }, Cmd.none )
    Checked value ->
      ( { model | checked = value, checks = value :: model.checks }, Cmd.none )


selectSpec : String -> Maybe (Spec Model Msg)
selectSpec name =
  case name of
    "input" -> Just inputSpec
    "check" -> Just checkSpec    
    _ -> Nothing


main =
  Runner.browserProgram selectSpec