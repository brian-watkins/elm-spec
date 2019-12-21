module Spec.Witness exposing
  ( Witness
  , forUpdate
  , log
  , observe
  )

{-| A `Witness` can be used to record information about the arguments passed to
a `Cmd`-generating function.

If you use dependency inversion to decouple part of your program from the
`Cmd`-generating functions it depends upon, you can use a `Witness` to prove that this
part of your program works with the `Cmd`-generating function in the right way.

Let's say I have a `Cmd`-generating function that takes a score (an `Int`) and saves
it to the server via some HTTP request. Let's further suppose I want to describe the behavior
of my user interface, without worrying about the details of how a score is saved. In this
case, I'll 'inject' the `Cmd`-generating function instead of calling it directly from my update
function. This allows me to substitute a fake function during my spec.

Here's the update function:

    update : (Int -> Cmd Msg) -> Msg -> Model -> (Model, Cmd Msg)
    update scoreSaver msg model =
      case msg of
        SaveScore score ->
          ( model, scoreSaver score )
        ...

Now, I can write a spec that uses a witness to record the score passed to the injected
`scoreSaver` function like so:

    Spec.describe "saving the score"
    [ Spec.scenario "successful save" (
        Spec.given (
          Spec.Setup.init (App.init testFlags)
            |> Spec.Setup.withView App.view
            |> Witness.forUpdate (\witness ->
              App.update <| \score ->
                Witness.log "saved-score"
                  (Json.Encode.int score) witness
            )
        )
        |> Spec.when "the score is saved"
          [ Spec.Markup.target << by [ id "game-over-button" ]
          , Spec.Markup.Event.click
          ]
        |> it "saves the proper score" (
          Witness.observe "saved-score" (Json.Decode.int)
            |> Spec.expect (Spec.Claim.isList
              [ Spec.Claim.isEqual Debug.toString 28
              ]
            )
        )
      )
    ]

@docs Witness, forUpdate, log, observe

-}

import Spec.Observer as Observer exposing (Observer)
import Spec.Observer.Internal as Observer
import Spec.Setup.Internal as Internal
import Spec.Setup as Setup exposing (Setup)
import Spec.Message as Message exposing (Message)
import Spec.Claim as Claim exposing (Claim)
import Spec.Report as Report exposing (Report)
import Json.Encode as Encode
import Json.Decode as Json


{-| Use a `Witness` to record information from inside a `Cmd`-generating function.
-}
type Witness msg =
  Witness (Message -> Cmd msg)


type alias Statement =
  { name: String
  , fact: Encode.Value
  }


{-| Set up the scenario with the update function from the program whose behavior is being
described. You'll have access to a `Witness` to use in constructing this function.

See the example above.
-}
forUpdate : (Witness msg -> msg -> model -> (model, Cmd msg)) -> Setup model msg -> Setup model msg
forUpdate updateWithWitness =
  Internal.mapSubject <| \subject ->
    { subject | update = \witness -> updateWithWitness <| Witness witness }


{-| Create a `Cmd` that logs some information.

Provide the name of this witness and a JSON value with any information to be logged.
-}
log : String -> Encode.Value -> Witness msg -> Cmd msg
log name statement (Witness witness) =
  Message.for "_witness" "log"
    |> Message.withBody (
      Encode.object
        [ ("name", Encode.string name)
        , ("fact", statement)
        ]
    )
    |> witness


{-| Observe the logs recorded by a witness.

Provide the name of the witness and a JSON decoder that can decode whatever
value you need to observe.
-}
observe : String -> Json.Decoder a -> Observer model (List a)
observe name decoder =
  Observer.observeEffects (\effects ->
    statementsForWitness name effects
        |> factsFromStatements decoder
  )
  |> Observer.mapRejection (\report ->
    Report.batch
    [ Report.fact "Claim rejected for witness" name
    , report
    ]
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
