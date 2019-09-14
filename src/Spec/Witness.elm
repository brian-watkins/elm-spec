module Spec.Witness exposing
  ( Witness
  , Statement
  , forUpdate
  , spy
  , expect
  , hasStatements
  )

import Spec.Observation as Observation exposing (Expectation)
import Spec.Subject as Subject exposing (Subject)
import Spec.Message as Message exposing (Message)
import Spec.Observer as Observer exposing (Observer)
import Spec.Observation.Report as Report
import Json.Encode as Encode
import Json.Decode as Json


type Witness msg =
  Witness (Message -> Cmd msg)


type alias Statement =
  { name: String
  }


forUpdate : (Witness msg -> msg -> model -> (model, Cmd msg)) -> Subject model msg -> Subject model msg
forUpdate updateWithWitness subject =
  { subject | update = \witness -> updateWithWitness <| Witness witness }


spy : String -> Witness msg -> Cmd msg
spy name (Witness witness) =
  witness
    { home = "_witness"
    , name = "spy"
    , body = Encode.object [ ("name", Encode.string name) ]
    }


expect : String -> Observer (List Statement) -> Expectation model
expect name observer =
  Observation.selectEffects
    |> Observation.mapSelection (filterStatementsFromWitness name)
    |> Observation.expect (\statements ->
      case observer statements of
        Observer.Accept ->
          Observer.Accept
        Observer.Reject report ->
          Observer.Reject <| Report.batch
            [ Report.fact "Expected witness" name
            , report
            ]
    )


filterStatementsFromWitness : String -> List Message -> List Statement
filterStatementsFromWitness name messages =
  List.filter (Message.is "_witness" "spy") messages
    |> List.filterMap (Message.decode statementDecoder)
    |> List.filter (\statement -> statement.name == name)


statementDecoder : Json.Decoder (Statement)
statementDecoder =
  Json.map Statement
    ( Json.field "name" Json.string )


hasStatements : Int -> Observer (List Statement)
hasStatements times statements =
  if times == List.length statements then
    Observer.Accept
  else
    Observer.Reject <| Report.batch
      [ Report.fact "to have been called" <| timesString times
      , Report.fact "but it was called" <| timesString <| List.length statements
      ]


timesString : Int -> String
timesString times =
  if times == 1 then
    (String.fromInt times) ++ " time"
  else
    (String.fromInt times) ++ " times"
