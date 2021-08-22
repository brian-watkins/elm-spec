module Harness.Subject exposing
  ( Model, Msg, Actions
  , defaultModel
  , view
  , update
  , subscriptions
  , programMsgTagger
  , urlChangeHandler
  , urlRequestHandler
  , programContext
  , initialCommand
  , storeEffect
  )

import Spec.Setup.Internal as Setup exposing (Subject)
import Spec.Message as Message exposing (Message)
import Spec.Step.Context as Context exposing (Context)
import Spec.Step.Message as Message
import Spec.Report as Report exposing (Report)
import Browser exposing (Document, UrlRequest)
import Html
import Browser exposing (UrlRequest)
import Url exposing (Url)
import Spec.Navigator.Internal exposing (..)


type alias Model model msg =
  { programModel: model
  , effects: List Message
  , subject: Subject model msg
  }


defaultModel : Subject model msg -> Model model msg
defaultModel subject =
  { programModel = subject.model
  , effects = []
  , subject = subject
  }


programContext : Model model msg -> Context model
programContext model =
  Context.for model.programModel
    |> Context.withEffects model.effects


initialCommand : Model model msg -> Cmd msg
initialCommand model =
  model.subject.initialCommand


type Msg msg
  = ReceivedMessage Message
  | ProgramMsg msg
  | OnUrlChange Url
  | OnUrlRequest UrlRequest
  | StoreEffect Message


programMsgTagger : msg -> Msg msg
programMsgTagger =
  ProgramMsg


urlChangeHandler : Url -> Msg msg
urlChangeHandler =
  OnUrlChange


urlRequestHandler : UrlRequest -> Msg msg
urlRequestHandler =
  OnUrlRequest


storeEffect : Message -> Msg msg
storeEffect =
  StoreEffect


view : (Msg programMsg -> msg) -> Model model programMsg -> Document msg
view sendToSelf model =
  case model.subject.view of
    Setup.Element v ->
      { title = "Harness Element Program"
      , body = [ v model.programModel |> Html.map (sendToSelf << ProgramMsg) ]
      }
    Setup.Document v ->
      let
        doc = v model.programModel
      in
        { title = doc.title
        , body =
            doc.body
              |> List.map (Html.map (sendToSelf << ProgramMsg))
        }


type alias Actions msg programMsg =
  { send: Message -> Cmd msg
  , sendCommand: Cmd programMsg -> Cmd msg
  , listen: (Message -> Msg programMsg) -> Sub msg
  , sendToSelf: Msg programMsg -> msg
  , abort: Report -> Cmd msg
  }


update : Actions msg programMsg -> Msg programMsg -> Model model programMsg -> ( Model model programMsg, Cmd msg )
update actions msg model =
  case msg of
    ProgramMsg programMsg ->
      model.subject.update programMsg model.programModel
        |> Tuple.mapFirst (\updated -> { model | programModel = updated })
        |> Tuple.mapSecond actions.sendCommand
    OnUrlChange url ->
      case model.subject.navigationConfig of
        Just navConfig ->
          update actions (ProgramMsg <| navConfig.onUrlChange url) model
        Nothing ->
          ( model
          , actions.abort <| Report.note "A URL change occurred for an application, but no handler has been provided. Use Spec.Setup.forNavigation to set a handler."
          )
    OnUrlRequest request ->
      case model.subject.navigationConfig of
         Just navConfig ->
          update actions (ProgramMsg <| navConfig.onUrlRequest request) model
         Nothing ->
          ( model
          , actions.abort <| Report.note "A URL request occurred for an application, but no handler has been provided. Use Spec.Setup.forNavigation to set a handler."
          )
    ReceivedMessage message ->
      if Message.is "_navigation" "assign" message then
        Message.decode navigationAssignmentDecoder message
          |> Result.map (\navAssignment ->
            ( { model | subject = navigatedSubject navAssignment.href model.subject }
            , Cmd.none
            )
          )
          |> Result.withDefault ( model, Cmd.none )
      else
        ( model, Cmd.none )
    StoreEffect message ->
      ( { model | effects = message :: model.effects }
      , Cmd.none
      )


subscriptions : Actions msg programMsg -> Model model programMsg -> Sub msg
subscriptions actions model =
  Sub.batch
  [ actions.listen ReceivedMessage
  , model.subject.subscriptions model.programModel
      |> Sub.map ProgramMsg
      |> Sub.map actions.sendToSelf
  ]