module Harness.Observe exposing 
  ( Model, defaultModel
  , Msg(..)
  , Actions
  , generateModel
  , init
  , update
  , ExposedExpectationRepository
  , subscriptions
  )

import Spec.Claim as Claim exposing (Verdict)
import Spec.Step.Context exposing (Context)
import Spec.Step.Message as Message
import Harness.Message as Message
import Spec.Message as Message exposing (Message)
import Spec.Observer.Message as Message
import Spec.Observer.Internal exposing (Judgment(..))
import Harness.Types exposing (..)
import Spec.Report as Report exposing (Report)
import Json.Decode as Json


type alias Model model =
  { inquiryHandler: Maybe (Message -> Judgment model)
  , expectation: Maybe (Expectation model)
  , description: String
  }


defaultModel : Model model
defaultModel =
  { inquiryHandler = Nothing
  , expectation = Nothing
  , description = ""
  }


toModel : String -> Expectation model -> Model model
toModel description expectation =
  { defaultModel
  | expectation = Just expectation
  , description = description
  }


type Msg
  = ReceivedMessage Message
  | Continue


type alias Actions msg =
  { send : Message -> Cmd msg
  , finished: Cmd msg
  , listen: (Message -> Msg) -> Sub msg
  , sendToSelf: Msg -> Cmd msg
  }


type alias ExposedExpectationRepository model =
  { get: String -> Maybe (ExposedExpectation model)
  }


type alias ObserverConfig =
  { name: String
  , expected: Json.Value
  , description: String
  }

generateModel : ExposedExpectationRepository model -> Message -> Result Report (Model model)
generateModel expectations message =
  Result.map3 ObserverConfig
    (Message.decode (Json.field "observer" Json.string) message)
    (Message.decode (Json.field "expected" Json.value) message)
    (Message.decode (Json.field "description" Json.string) message)
    |> Result.mapError Report.note
    |> Result.andThen (\config ->
      tryToGenerateExpectation expectations config
        |> Result.map (toModel config.description)
    )


tryToGenerateExpectation : ExposedExpectationRepository model -> ObserverConfig -> Result Report (Expectation model)
tryToGenerateExpectation expectations config =
  case expectations.get config.name of
    Just expectationGenerator ->
      expectationGenerator config.expected
    Nothing ->
      Err <| Report.note <| "No expectation has been exposed with the name " ++ config.name


init : Actions msg -> Model model -> ( Model model, Cmd msg )
init actions model =
  ( model
  , actions.sendToSelf Continue
  )


update : Actions msg -> Context model -> Msg -> Model model -> ( Model model, Cmd msg )
update actions context msg model =
  case msg of
    ReceivedMessage message ->
      if Message.belongsTo "_observer" message then
        handleObserveMessage actions model message
      else
        ( model, Cmd.none )
    Continue ->
      case model.expectation of
        Just expectation ->
          observe actions context model expectation
        Nothing ->
          ( model, Cmd.none )


observe : Actions msg -> Context model -> Model model -> Expectation model -> ( Model model, Cmd msg )
observe config context model (Expectation expectation) =
  case expectation context of
    Complete verdict ->
      ( model
      , sendVerdict config model.description verdict
      )
    Inquire message handler ->
      ( { model | inquiryHandler = Just handler }
      , config.send <| Message.inquiry message
      )


handleObserveMessage : Actions msg -> Model model -> Message -> ( Model model, Cmd msg )
handleObserveMessage actions model message =
  Message.decode Message.inquiryDecoder message
    |> Result.map .message
    |> Result.map (processInquiryMessage actions model)
    |> Result.withDefault
      ( model
      , sendVerdict actions model.description <| Claim.Reject <| Report.note "Unable to decode inquiry result!"
      )


processInquiryMessage : Actions msg -> Model model -> Message -> ( Model model, Cmd msg )
processInquiryMessage actions model message =
  if Message.is "_scenario" "abort" message then
    ( model
    , Message.decode Report.decoder message
        |> Result.withDefault (Report.note "Unable to parse abort scenario event!")
        |> Claim.Reject
        |> sendVerdict actions model.description
    )
  else
    ( { model | inquiryHandler = Nothing }
    , handleInquiry message model.inquiryHandler
        |> sendVerdict actions model.description
    )


handleInquiry : Message -> Maybe (Message -> Judgment model) -> Verdict
handleInquiry message maybeHandler =
  maybeHandler
    |> Maybe.map (inquiryResult message)
    |> Maybe.withDefault (Claim.Reject <| Report.note "No Inquiry Handler!")


inquiryResult : Message -> (Message -> Judgment model) -> Verdict
inquiryResult message handler =
  case handler message of
    Complete verdict ->
      verdict
    Inquire _ _ ->
      Claim.Reject <| Report.note "Recursive Inquiry not supported!"


sendVerdict : Actions msg -> String -> Verdict -> Cmd msg
sendVerdict actions message verdict =
  Cmd.batch
    [ Message.observation [] message verdict
        |> actions.send
    , actions.finished
    ]


subscriptions : Actions msg -> Model model -> Sub msg
subscriptions actions _ =
  actions.listen (\message ->
    if Message.is "_scenario" "state" message then
      case Message.decode Json.string message |> Result.withDefault "" of
        "CONTINUE" ->
          Continue
        _ ->
          ReceivedMessage message
    else
      ReceivedMessage message
  )