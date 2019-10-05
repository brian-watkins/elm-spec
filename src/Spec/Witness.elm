module Spec.Witness exposing
  ( Witness
  , forUpdate
  , log
  , expect
  )

import Spec.Observation as Observation exposing (Expectation)
import Spec.Subject as Subject exposing (SubjectGenerator)
import Spec.Message as Message exposing (Message)
import Spec.Observer as Observer exposing (Observer)
import Spec.Observation.Report as Report
import Json.Encode as Encode
import Json.Decode as Json


type Witness msg =
  Witness (Message -> Cmd msg)


type alias Statement =
  { name: String
  , fact: Encode.Value
  }


forUpdate : (Witness msg -> msg -> model -> (model, Cmd msg)) -> SubjectGenerator model msg -> SubjectGenerator model msg
forUpdate updateWithWitness =
  Subject.mapSubject <| \subject ->
    { subject | update = \witness -> updateWithWitness <| Witness witness }


log : String -> Encode.Value -> Witness msg -> Cmd msg
log name statement (Witness witness) =
  witness
    { home = "_witness"
    , name = "log"
    , body =
        Encode.object
          [ ("name", Encode.string name)
          , ("fact", statement)
          ]
    }


expect : String -> Json.Decoder a -> Observer (List a) -> Expectation model
expect name decoder observer =
  Observation.selectEffects
    |> Observation.mapSelection (statementsForWitness name)
    |> Observation.mapSelection (factsFromStatements decoder)
    |> Observation.expect (\facts ->
      observer facts
        |> Observer.mapRejection (
          Report.append <|
            Report.fact "Observation rejected for witness" name
        )
    )


statementsForWitness : String -> List Message -> List Statement
statementsForWitness name messages =
  List.filter (Message.is "_witness" "log") messages
    |> List.filterMap (Message.decode statementDecoder)
    |> List.filter (\statement -> 
        statement.name == name
    )
    |> List.reverse


factsFromStatements : Json.Decoder a -> List Statement -> List a
factsFromStatements decoder =
  List.filterMap (\statement ->
    Json.decodeValue decoder statement.fact
      |> Result.toMaybe
  )


statementDecoder : Json.Decoder (Statement)
statementDecoder =
  Json.map2 Statement
    ( Json.field "name" Json.string )
    ( Json.field "fact" Json.value )
