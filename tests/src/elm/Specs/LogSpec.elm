module Specs.LogSpec exposing (main)

import Spec exposing (..)
import Spec.Setup as Setup
import Spec.Observer as Observer
import Spec.Step as Step
import Spec.Report as Report
import Specs.Helpers exposing (..)
import Runner


logReportSpec : Spec Model Msg
logReportSpec =
  Spec.describe "log report"
  [ scenario "logging a report during a scenario" (
      given (
        Setup.initWithModel { count = 7 }
      )
      |> when "a report is logged"
        [ \_ -> Step.log <| Report.batch
            [ Report.note "This is a log message!"
            , Report.note "And this is another message!"
            ]
        , \context ->
            Step.model context
              |> .count
              |> String.fromInt
              |> Report.fact "This is the count in the model!"
              |> Step.log
        ]
      |> it "still completes the scenario" (
        Observer.observeModel .count
          |> expect (equals 7)
      )
    )
  ]


type alias Model =
  { count: Int
  }


type Msg =
  Msg


selectSpec : String -> Maybe (Spec Model Msg)
selectSpec specName =
  case specName of
    "logReport" -> Just logReportSpec
    _ -> Nothing


main =
  Runner.program selectSpec