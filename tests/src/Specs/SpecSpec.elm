port module Specs.SpecSpec exposing (..)

import Spec exposing (Spec)
import Spec.Subject as Subject
import Spec.Scenario exposing (..)
import Spec.Port as Port
import Spec.Claim as Claim
import Spec.Observer as Observer
import Runner
import Json.Encode as Encode
import Json.Decode as Json
import Specs.Helpers exposing (..)


noScenariosSpec : Spec Model Msg
noScenariosSpec =
  Spec.describe "nothing" []


multipleWhenSpec : Spec Model Msg
multipleWhenSpec =
  Spec.describe "A Spec"
  [ scenario "multiple when blocks" (
      given testSubject
      |> when "the first two subs are sent"
        [ sendMessageWith 41
        , sendMessageWith 78
        ]
      |> when "a third sub is sent"
        [ sendMessageWith 39
        ]
      |> it "updates the model with all three subscriptions" (
          Observer.observeModel .counts
            |> expect (equals [ 39, 78, 41 ])
      )
    )
  ]


testSubject =
  Subject.init ( { counts = [] }, Cmd.none )
      |> Subject.withUpdate testUpdate
      |> Subject.withSubscriptions testSubscriptions


multipleScenariosSpec : Spec Model Msg
multipleScenariosSpec =
  Spec.describe "Multiple scenarios"
  [ scenario "the happy path" (
      given testSubject
      |> when "a single message is sent"
        [ sendMessageWith 87
        ]
      |> it "records the number" (
        Observer.observeModel .counts
          |> expect (equals [ 87 ])
      )
    )
  , scenario "multiple sub messages are sent" (
      given testSubject
      |> when "multiple messages are sent"
        [ sendMessageWith 87
        , sendMessageWith 65
        ]
      |> it "records the numbers" (
        Observer.observeModel .counts
          |> expect (equals [ 65, 87 ])
      )
    )
  , scenario "a different message is sent" (
      given testSubject
      |> when "a single message is sent"
        [ sendMessageWith 14
        ]
      |> it "records the number" (
        Observer.observeModel .counts
          |> expect (equals [ 14 ])
      )
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