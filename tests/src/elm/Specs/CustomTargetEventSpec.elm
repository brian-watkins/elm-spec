module Specs.CustomTargetEventSpec exposing (main)

import Spec exposing (..)
import Spec.Setup as Setup
import Spec.Markup as Markup
import Spec.Markup.Selector exposing (..)
import Spec.Markup.Event as Event
import Spec.Claim exposing (..)
import Specs.Helpers exposing (..)
import Runner
import Json.Encode as Encode
import Json.Decode as Json
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events


customTargetSpec : Spec Model Msg
customTargetSpec =
  describe "event triggered with a custom target"
  [ scenario "the event is triggered with properties on the target" (
      given (
        Setup.initWithModel testModel
          |> Setup.withUpdate testUpdate
          |> Setup.withView testView
      )
      |> when "the event is triggered"
        [ Markup.target << by [ tag "video" ]
        , Event.trigger "loadedmetadata" <|
            Encode.object
              [ ( "target"
                , Encode.object
                  [ ("videoWidth", Encode.float 200.0)
                  , ("videoHeight", Encode.float 300.0)
                  ] 
                )
              ]
        ]
      |> it "displays the values from the event" (
        Markup.observeElement
          |> Markup.query << by [ id "video-size" ]
          |> expect (isSomethingWhere <| Markup.text <| equals "Video Size: 200 x 300")
      )
    )
  ]


type alias Model =
  { width: Float
  , height: Float
  }


testModel : Model
testModel =
  { width = 0.0
  , height = 0.0
  }


type Msg
  = LoadedMetadata Model


testUpdate : Msg -> Model -> ( Model, Cmd Msg )
testUpdate msg _ =
  case msg of
    LoadedMetadata updatedModel ->
      ( updatedModel, Cmd.none )


testView : Model -> Html Msg
testView model =
  Html.div []
  [ Html.video [ onLoadedMetadata LoadedMetadata ] []
  , Html.div [ Attr.id "video-size"]
    [ Html.text <|
        "Video Size: "
          ++ String.fromFloat model.width
          ++ " x "
          ++ String.fromFloat model.height
    ]
  ]


onLoadedMetadata : (Model -> msg) -> Html.Attribute msg
onLoadedMetadata tagger =
  Events.on "loadedmetadata" <| (Json.map tagger <|
    Json.map2 Model
      ( Json.at [ "target", "videoWidth" ] Json.float )
      ( Json.at [ "target", "videoHeight" ] Json.float )
  )


selectSpec : String -> Maybe (Spec Model Msg)
selectSpec name =
  case name of
    "customTarget" -> Just customTargetSpec
    _ -> Nothing


main =
  Runner.browserProgram selectSpec