module Specs.ProgramSpec exposing (main)

import Spec exposing (..)
import Spec.Setup as Setup
import Spec.Observer as Observer
import Spec.Claim exposing (..)
import Spec.Markup as Markup
import Spec.Markup.Selector exposing (..)
import Spec.Markup.Event as Event
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Runner
import Specs.Helpers exposing (..)


wrappedProgramSpec : Spec Model Msg
wrappedProgramSpec =
  describe "wrapped program"
  [ scenario "the wrapped program returns Cmd.none" (
      given (
        Setup.initWithModel testModel
          |> Setup.withView testView
          |> Setup.withUpdate testUpdate
      )
      |> when "the button is clicked"
        [ Markup.target << by [ id "trigger" ]
        , Event.click
        , Event.click
        , Event.click
        ]
      |> it "updates the count" (
        Observer.observeModel .programModel
          |> expect (specifyThat .count <| equals 3)
      )
    )
  ]


type alias Model =
  { programModel: ProgramModel
  }


type alias ProgramModel =
  { count: Int
  }


testModel =
  { programModel = { count = 0 }
  }


testView : Model -> Html Msg
testView model =
  programView model.programModel
    |> Html.map ProgMsg


programView : ProgramModel -> Html ProgramMsg
programView _ =
  Html.div []
  [ Html.button [ Attr.id "trigger", Events.onClick HandleClick ] [ Html.text "Increment!" ]
  ]


type Msg
  = ProgMsg ProgramMsg

type ProgramMsg
  = HandleClick

testUpdate : Msg -> Model -> (Model, Cmd Msg)
testUpdate msg model =
  case msg of
    ProgMsg pmsg ->
      programUpdate pmsg model.programModel
        |> Tuple.mapFirst (\updated -> { model | programModel = updated })
        |> Tuple.mapSecond (Cmd.map ProgMsg)


programUpdate : ProgramMsg -> ProgramModel -> (ProgramModel, Cmd ProgramMsg)
programUpdate msg model =
  case msg of
    HandleClick ->
      ( { model | count = model.count + 1 }, Cmd.none )


selectSpec : String -> Maybe (Spec Model Msg)
selectSpec name =
  case name of
    "wrappedProgram" -> Just wrappedProgramSpec
    _ -> Nothing


main =
  Runner.browserProgram selectSpec

