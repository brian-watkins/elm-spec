module Harness.Program exposing
  ( init
  , Msg
  , Model
  , Flags
  , Config
  , update
  , view
  , subscriptions
  , onUrlChange
  , onUrlRequest
  , Expectation(..)
  )

import Spec.Message exposing (Message)
import Browser.Navigation exposing (Key)
import Browser exposing (UrlRequest, Document)
import Spec.Setup.Internal as Setup exposing (Subject)
import Spec.Step.Context as Context exposing (Context)
import Spec.Observer.Internal as Observer exposing (Judgment(..))
import Spec.Message as Message
import Spec.Observer.Message as Message
import Spec.Setup exposing (Setup)
import Spec.Claim exposing (Verdict)
import Url exposing (Url)
import Html exposing (Html)
import Spec.Setup.Internal exposing (initializeSubject)
import Dict exposing (Dict)
import Json.Decode as Json
import Json.Encode as Encode

type alias Config msg =
  { send: Message -> Cmd (Msg msg)
  , listen: (Message -> Msg msg) -> Sub (Msg msg)
  }

type Expectation model =
  Expectation
    (Observer.Expectation model)


type Msg msg
  = ProgramMsg msg
  | SendMessage Message
  | ReceivedMessage Message
  | OnUrlRequest UrlRequest
  | OnUrlChange Url


type Model model msg
  = Waiting
  | Running (HarnessModel model msg)

type alias HarnessModel model msg =
  { subject: Subject model msg
  , programModel: model
  , effects: List Message
  }

type alias Flags =
  { }


init : Setup model msg -> ( Model model msg, Cmd (Msg msg) )
init setup =
  let
    -- probably don't want to do this here but once we get the start message we should initialize the harness
    -- subject. BUT would we have multiple setups in the same harness? It might fire a command though ...
    -- It might not be that we have multiple setup functions ... but it might be that we have one function
    -- that takes an argument resulting in different setups. But in any case, if we want to be able to
    -- run multiple times, we can't do this (only) in the init. But fine for now.
    maybeSubject = initializeSubject setup Nothing
  in
    case maybeSubject of
      Ok subject ->
        ( Running { subject = subject, programModel = subject.model, effects = [] }, Cmd.none )
      Err _ ->
        ( Waiting, Cmd.none )


view : Model model msg -> Document (Msg msg)
view model =
  case model of
    Running harnessModel ->
      case harnessModel.subject.view of
        Setup.Element v ->
          { title = "Harness Element Program"
          , body = [ v harnessModel.programModel |> Html.map ProgramMsg ]
          }
        Setup.Document v ->
          let
            doc = v harnessModel.programModel
          in
            { title = doc.title
            , body =
                doc.body
                  |> List.map (Html.map ProgramMsg)
            }
    Waiting ->
      { title = "Harness Program"
      , body = [ fakeBody ]
      }


fakeBody : Html (Msg msg)
fakeBody =
  Html.div []
    [ Html.text "Waiting ..."
    ]

type alias ExposedExpectation model =
  Json.Value -> Expectation model


update : Config msg -> Dict String (ExposedExpectation model) -> Msg msg -> Model model msg -> ( Model model msg, Cmd (Msg msg) )
update config expectations msg model =
  case msg of
    ReceivedMessage message ->
      let
        d = Debug.log "got message!!" message
      in
        if Message.is "_harness" "observe" message then
          let
            maybeExpectation = Message.decode (Json.field "observer" Json.string) message
              |> Result.toMaybe
              |> Maybe.andThen (\observerName -> Dict.get observerName expectations)
            expected = Message.decode (Json.field "expected" Json.value) message
              |> Result.toMaybe
              |> Maybe.withDefault Encode.null
          in
            case maybeExpectation of
              Just expectation ->
                case model of
                  Running harness ->
                    observe config harness (expectation expected)
                  Waiting ->
                    ( model, Cmd.none )
              Nothing ->
                ( model, Cmd.none )
        else
          ( model, Cmd.none )
    _ ->
      ( model, Cmd.none )


observe : Config msg -> HarnessModel model msg -> Expectation model -> ( Model model msg, Cmd (Msg msg) )
observe config model (Expectation expectation) =
  case expectation <| establishContext model.programModel model.effects of
    Complete verdict ->
      ( Running model
      , sendVerdict config verdict 
      )
    Inquire message handler ->
      -- Not handling this yet
      ( Running model
      , Cmd.none
      )


establishContext : model -> List Message -> Context model
establishContext programModel effects =
  Context.for programModel
    |> Context.withEffects effects

sendVerdict : Config msg -> Verdict -> Cmd (Msg msg)
sendVerdict config verdict =
  Message.observation [] "harness observation" verdict
    |> config.send


subscriptions : Config msg -> Model model msg -> Sub (Msg msg)
subscriptions config _ =
  config.listen ReceivedMessage


onUrlRequest : UrlRequest -> (Msg msg)
onUrlRequest =
  OnUrlRequest


onUrlChange : Url -> (Msg msg)
onUrlChange =
  OnUrlChange