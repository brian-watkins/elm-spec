module Specs.EventSpec exposing (..)

import Spec exposing (Spec)
import Spec.Subject as Subject
import Spec.Scenario exposing (..)
import Spec.Step as Step
import Spec.Markup as Markup
import Spec.Markup.Selector exposing (..)
import Spec.Markup.Event as Event
import Spec.Observer as Observer
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Runner
import Json.Decode as Json
import Json.Encode as Encode


inputSpec : Spec Model Msg
inputSpec =
  Spec.describe "an html program"
  [ scenario "Input event" (
      given (
        Subject.initWithModel { message = "" }
          |> Subject.withUpdate testUpdate
          |> Subject.withView testView
      )
      |> when "some text is input"
        [ target << by [ id "my-field" ]
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
        Subject.initWithModel { message = "" }
          |> Subject.withUpdate testUpdate
          |> Subject.withView testView
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


customEventSpec : Spec Model Msg
customEventSpec =
  Spec.describe "program that uses a custom event"
  [ scenario "trigger a custom event" (
      given (
        Subject.initWithModel { message = "" }
          |> Subject.withUpdate testUpdate
          |> Subject.withView testView
      )
      |> when "some event is triggered"
        [ target << by [ id "my-typing-place" ]
        , keyUpEvent 65
        , keyUpEvent 66
        , keyUpEvent 67
        ]
      |> it "does what it should" (
        Markup.observeElement
          |> Markup.query << by [ id "my-message" ]
          |> expect (Markup.hasText "You wrote: ABC")
      )
    )
  , scenario "no element targeted for custom event" (
      given (
        Subject.initWithModel { message = "" }
          |> Subject.withUpdate testUpdate
          |> Subject.withView testView
      )
      |> when "some event is triggered without targeting an element first"
        [ keyUpEvent 65
        ]
      |> it "fails" (
        Markup.observeElement
          |> Markup.query << by [ id "my-message" ]
          |> expect (Markup.hasText "You wrote: A")
      )
    )
  ]


keyUpEvent : Int -> Step.Context model -> Step.Command msg
keyUpEvent code =
  Encode.object
    [ ( "keyCode", Encode.int code )
    ]
    |> Event.trigger "keyup"


type Msg
  = GotText String
  | GotKey Int


type alias Model =
  { message: String
  }


testUpdate : Msg -> Model -> (Model, Cmd Msg)
testUpdate msg model =
  case msg of
    GotText message ->
      ( { model | message = message }, Cmd.none )
    GotKey key ->
      let
        letter =
          Char.fromCode key
            |> String.fromChar
      in
        ( { model | message = model.message ++ letter }, Cmd.none )


testView : Model -> Html Msg
testView model =
  Html.div []
  [ Html.input [ Attr.id "my-field", Events.onInput GotText ] []
  , Html.input [ Attr.id "my-typing-place", onKeyUp GotKey ] []
  , Html.div [ Attr.id "my-message" ] [ Html.text <| "You wrote: " ++ model.message ]
  ]


onKeyUp : (Int -> Msg) -> Html.Attribute Msg
onKeyUp tagger =
  Events.on "keyup" (Json.map tagger Events.keyCode)


selectSpec : String -> Maybe (Spec Model Msg)
selectSpec name =
  case name of
    "input" -> Just inputSpec
    "custom" -> Just customEventSpec
    _ -> Nothing


main =
  Runner.browserProgram selectSpec