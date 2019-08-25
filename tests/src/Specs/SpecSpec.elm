port module Specs.SpecSpec exposing (..)

import Spec exposing (Spec)
import Spec.Subject as Subject
import Spec.Port as Port
import Spec.Observer as Observer
import Spec.Actual as Actual
import Runner
import Json.Encode as Encode
import Json.Decode as Json


multipleWhenSpec : Spec Model Msg
multipleWhenSpec =
  Spec.given "a test worker" (
    Subject.init ( { counts = [] }, Cmd.none )
      |> Subject.withUpdate testUpdate
      |> Subject.withSubscriptions testSubscriptions
  )
  |> Spec.when "the first sub is sent"
    [ Port.send "specSpecSub" <| subMessageWith 41
    ]
  |> Spec.when "a second sub is sent"
    [ Port.send "specSpecSub" <| subMessageWith 78
    ]
  |> Spec.when "a third sub is sent"
    [ Port.send "specSpecSub" <| subMessageWith 39
    ]
  |> Spec.it "updates the model with all three subscriptions" (
      Actual.model
        |> Actual.map .counts
        |> Spec.expect (Observer.isEqual [ 39, 78, 41 ])
  )


multipleScenariosSpec : Spec Model Msg
multipleScenariosSpec =
  Spec.given "a test worker" (
    Subject.init ( { counts = [] }, Cmd.none )
      |> Subject.withUpdate testUpdate
      |> Subject.withSubscriptions testSubscriptions
  )
  |> Spec.when "the first sub is sent"
    [ Port.send "specSpecSub" <| subMessageWith 87
    ]
  |> Spec.it "records the first number" (
      Actual.model
        |> Actual.map .counts
        |> Spec.expect (Observer.isEqual [ 87 ])
  )
  |> Spec.suppose (
    Spec.given "another scenario"
      >> Spec.when "another sub is sent"
        [ Port.send "specSpecSub" <| subMessageWith 82 ]
      >> Spec.it "records the second number" (
        Actual.model
          |> Actual.map .counts
          |> Spec.expect (Observer.isEqual [ 82, 87 ])
      )
      >> Spec.suppose (
        Spec.given "a final scenario"
          >> Spec.when "the final sub is sent"
            [ Port.send "specSpecSub" <| subMessageWith 0 ]
          >> Spec.it "records the final number" (
            Actual.model
              |> Actual.map .counts
              |> Spec.expect (Observer.isEqual [ 0, 82, 87 ])
          )
      )
  )
  |> Spec.suppose (
    Spec.given "an awesome scenario"
      >> Spec.when "another awesome sub is sent"
        [ Port.send "specSpecSub" <| subMessageWith 41 ]
      >> Spec.it "records the second awesome number" (
        Actual.model
          |> Actual.map .counts
          |> Spec.expect (Observer.isEqual [ 41, 87 ])
      )
  )


subMessageWith : Int -> Json.Value
subMessageWith number =
  Encode.object [ ("number", Encode.int number) ]


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