port module Specs.SpecSpec exposing (..)

import Spec exposing (Spec)
import Spec.Subject as Subject
import Spec.Port as Port
import Spec.Observer as Observer
import Spec.Actual as Actual
import Runner
import Json.Encode as Encode
import Json.Decode as Json


noScenariosSpec : Spec Model Msg
noScenariosSpec =
  Spec.describe "nothing" []


multipleWhenSpec : Spec Model Msg
multipleWhenSpec =
  Spec.describe "A Spec"
  [ Spec.scenario "multiple when blocks" testSubject
      |> Spec.when "the first two subs are sent"
        [ sendMessageWith 41
        , sendMessageWith 78
        ]
      |> Spec.when "a third sub is sent"
        [ sendMessageWith 39
        ]
      |> Spec.it "updates the model with all three subscriptions" (
          Actual.model
            |> Actual.map .counts
            |> Spec.expect (Observer.isEqual [ 39, 78, 41 ])
      )
  ]


testSubject =
  Subject.init ( { counts = [] }, Cmd.none )
      |> Subject.withUpdate testUpdate
      |> Subject.withSubscriptions testSubscriptions


multipleScenariosSpec : Spec Model Msg
multipleScenariosSpec =
  Spec.describe "Multiple scenarios"
  [ Spec.scenario "the happy path" testSubject
      |> Spec.when "a single message is sent"
        [ sendMessageWith 87
        ]
      |> Spec.it "records the number" (
        Actual.model
          |> Actual.map .counts
          |> Spec.expect (Observer.isEqual [ 87 ])
      )
  , Spec.scenario "multiple sub messages are sent" testSubject
      |> Spec.when "multiple messages are sent"
        [ sendMessageWith 87
        , sendMessageWith 65
        ]
      |> Spec.it "records the numbers" (
        Actual.model
          |> Actual.map .counts
          |> Spec.expect (Observer.isEqual [ 65, 87 ])
      )
  , Spec.scenario "a different message is sent" testSubject
      |> Spec.when "a single message is sent"
        [ sendMessageWith 14
        ]
      |> Spec.it "records the number" (
        Actual.model
          |> Actual.map .counts
          |> Spec.expect (Observer.isEqual [ 14 ])
      )
  ]


sendMessageWith number =
  Port.send "specSpecSub" <| Encode.object [ ("number", Encode.int number) ]


testUpdate : Msg -> Model -> ( Model, Cmd Msg )
testUpdate msg model =
  case msg of
    ReceivedSuperObject superObject ->
      ( { model | counts = superObject.number :: model.counts }, Cmd.none )


selectSpec : String -> Maybe (Spec Model Msg)
selectSpec name =
  case name of
    "multipleWhen" -> Just multipleWhenSpec
    "scenarios" -> Just multipleScenariosSpec
    "noScenarios" -> Just noScenariosSpec
    _ -> Nothing


type alias SuperObject =
  { number: Int
  }


type Msg
  = ReceivedSuperObject SuperObject


type alias Model =
  { counts: List Int
  }


port specSpecSub : (SuperObject -> msg) -> Sub msg


testSubscriptions : Model -> Sub Msg
testSubscriptions model =
  specSpecSub ReceivedSuperObject


main =
  Runner.program selectSpec