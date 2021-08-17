module Animation.App exposing (..)

import Browser.Dom
import Browser.Events
import Html exposing (Html)
import Html.Events as Events
import Html.Attributes as Attr
import Task


type alias Model =
  { loops: Int
  , focus: Int
  , elements: List Browser.Dom.Element
  }


testModel =
  { loops = 0
  , focus = 0
  , elements = []
  }


type Msg
  = OnAnimationFrame
  | GotElement (Result Browser.Dom.Error Browser.Dom.Element)
  | DidFocus


view : Model -> Html Msg
view model =
  Html.div []
  [ Html.input [ Attr.id "focus-element", Events.onFocus DidFocus ] []
  , Html.div [ Attr.id "loops" ]
    [ Html.text <| String.fromInt model.loops ++ " loops!" ]
  ]


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    OnAnimationFrame ->
      ( { model | loops = model.loops + 1 }
      , Browser.Dom.getElement "focus-element"
          |> Task.attempt GotElement
      )
    GotElement result ->
      case result of
        Ok element ->
          ( { model | elements = element :: model.elements }, Cmd.none )
        Err _ ->
          ( model, Cmd.none )
    DidFocus ->
      ( { model | focus = model.focus + 1 }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
  Browser.Events.onAnimationFrame (\_ -> OnAnimationFrame)
