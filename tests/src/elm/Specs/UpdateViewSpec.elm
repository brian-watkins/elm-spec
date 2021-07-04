port module Specs.UpdateViewSpec exposing (main)

import Spec exposing (..)
import Spec.Setup as Setup
import Spec.Port as Port
import Spec.Markup as Markup
import Spec.Markup.Selector exposing (..)
import Spec.Claim exposing (..)
import Spec.Observer as Observer
import Specs.Helpers exposing (..)
import Runner
import Json.Encode as Encode
import Html exposing (Html)
import Html.Attributes as Attr
import Browser.Dom
import Task


updateViewFromPort : Spec Model Msg
updateViewFromPort =
  describe "Update view"
  [ scenario "a port subscription results in a view update" (
      given (
        Setup.initWithModel testModel
          |> Setup.withUpdate testUpdate
          |> Setup.withView testView
          |> Setup.withSubscriptions testSubscriptions
      )
      |> when "a message is received via the port"
        [ Port.send "updateViewPort" <| Encode.string "Hello!!"
        ]
      |> observeThat
        [ it "updates the view" (
            Markup.observeElement
              |> Markup.query << by [ id "test-element" ]
              |> expect (isSomethingWhere <| Markup.text <| equals "Hello!!")
          )
        , it "gets the element details" (
            Observer.observeModel .element
              |> expect isSomething
          ) 
        ]
    )
  ]


type Msg
  = ReceivedMessage String
  | GotElement (Result Browser.Dom.Error Browser.Dom.Element)


type alias Model =
  { name: Maybe String
  , element: Maybe Browser.Dom.Element
  }


testModel : Model
testModel =
  { name = Nothing
  , element = Nothing
  }


testUpdate : Msg -> Model -> ( Model, Cmd Msg )
testUpdate msg model =
  case msg of
    ReceivedMessage name ->
      ( { model | name = Just name }
      , Browser.Dom.getElement "test-element"
          |> Task.attempt GotElement
      )
    GotElement result ->
      ( result
        |> Result.map (\element ->
          { model | element = Just element }
        )
        |> Result.withDefault model
      , Cmd.none
      )


testView : Model -> Html Msg
testView model =
  case model.name of
    Just name ->
      Html.div [ Attr.id "test-element" ]
        [ Html.text name ]
    Nothing ->
      Html.div [] []


testSubscriptions : Model -> Sub Msg
testSubscriptions _ =
  updateViewPort ReceivedMessage


port updateViewPort : (String -> msg) -> Sub msg


selectSpec : String -> Maybe (Spec Model Msg)
selectSpec name =
  case name of
    "fromPort" -> Just updateViewFromPort
    _ -> Nothing


main =
  Runner.browserProgram selectSpec

