module Spec.Witness exposing
  ( Witness
  , forUpdate
  , log
  , observe
  )

import Spec.Observer as Observer exposing (Observer)
import Spec.Scenario.Internal as Internal
import Spec.Subject as Subject exposing (SubjectProvider)
import Spec.Message as Message exposing (Message)
import Spec.Claim as Claim exposing (Claim)
import Spec.Report as Report exposing (Report)
import Json.Encode as Encode
import Json.Decode as Json


type Witness msg =
  Witness (Message -> Cmd msg)


type alias Statement =
  { name: String
  , fact: Encode.Value
  }


forUpdate : (Witness msg -> msg -> model -> (model, Cmd msg)) -> SubjectProvider model msg -> SubjectProvider model msg
forUpdate updateWithWitness =
  Internal.mapSubject <| \subject ->
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


observe : String -> Json.Decoder a -> Observer model (List a)
observe name decoder =
  Observer.observeEffects (\effects ->
    statementsForWitness name effects
        |> factsFromStatements decoder
  )
  |> Observer.mapRejection (
    Report.append <|
      Report.fact "Claim rejected for witness" name
  )
  |> Observer.observeResult


statementsForWitness : String -> List Message -> List Statement
statementsForWitness name messages =
  List.filter (Message.is "_witness" "log") messages
    |> List.filterMap (Message.decode statementDecoder)
    |> List.filter (\statement -> 
        statement.name == name
    )
    |> List.reverse


factsFromStatements : Json.Decoder a -> List Statement -> Result Report (List a)
factsFromStatements decoder =
  List.foldl (\statement ->
    Result.andThen (\facts ->
      Json.decodeValue decoder statement.fact
        |> Result.map (\fact -> List.append facts [ fact ])
        |> Result.mapError jsonErrorToReport
    )
  ) (Ok [])


jsonErrorToReport : Json.Error -> Report
jsonErrorToReport =
  Report.fact "Unable to decode statement recorded by witness" << Json.errorToString


statementDecoder : Json.Decoder (Statement)
statementDecoder =
  Json.map2 Statement
    ( Json.field "name" Json.string )
    ( Json.field "fact" Json.value )
