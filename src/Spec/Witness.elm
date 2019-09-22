module Spec.Witness exposing
  ( Witness
  , Statement
  , forUpdate
  , log
  , expect
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
  , content: Encode.Value
  }


forUpdate : (Witness msg -> msg -> model -> (model, Cmd msg)) -> Subject model msg -> Subject model msg
forUpdate updateWithWitness subject =
  { subject | update = \witness -> updateWithWitness <| Witness witness }


log : String -> Encode.Value -> Witness msg -> Cmd msg
log name statement (Witness witness) =
  witness
    { home = "_witness"
    , name = "log"
    , body =
        Encode.object
          [ ("name", Encode.string name)
          , ("content", statement)
          ]
    }


expect : String -> Json.Decoder a -> Observer (List a) -> Expectation model
expect name decoder observer =
  Observation.selectEffects
    |> Observation.mapSelection (filterStatementsFromWitness name decoder)
    |> Observation.expect (\statements ->
      case observer statements of
        Observer.Accept ->
          Observer.Accept
        Observer.Reject report ->
          Observer.Reject <| Report.batch
            [ Report.fact "Observation rejected for witness" name
            , report
            ]
    )


filterStatementsFromWitness : String -> Json.Decoder a -> List Message -> List a
filterStatementsFromWitness name decoder messages =
  List.filter (Message.is "_witness" "log") messages
    |> List.filterMap (Message.decode statementDecoder)
    |> List.filter (\statement -> 
        statement.name == name
    )
    |> List.filterMap (\statement -> 
        Json.decodeValue decoder statement.content
          |> Result.toMaybe
    )
    |> List.reverse


statementDecoder : Json.Decoder (Statement)
statementDecoder =
  Json.map2 Statement
    ( Json.field "name" Json.string )
    ( Json.field "content" Json.value )
