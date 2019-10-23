module Spec.Observation.Expectation exposing
  ( Model, Msg(..), init, update
  , Judgment(..)
  , Expectation(..)
  , Command(..)
  , Context
  )

import Spec.Message as Message exposing (Message)
import Spec.Claim as Claim exposing (Verdict)
import Spec.Observation.Report as Report
import Spec.Observation.Message as Message


type Expectation model =
  Expectation
    (Context model -> Judgment model)


type alias Context model =
  { model: model
  , effects: List Message
  }


type Judgment model
  = Complete Verdict
  | Inquire Message (Message -> Judgment model)


type alias Model model =
  { inquiryHandler: (Message -> Judgment model)
  }

type Msg model
  = Run (Context model) (Expectation model)
  | HandleInquiry Message


init : Model model
init =
  { inquiryHandler = (\_ -> Complete <| Claim.Reject <| Report.note "Unknown Inquiry" )
  }


type Command
  = Done Verdict
  | Send Message


update : Msg model -> Model model -> (Model model, Command)
update msg model =
  case msg of
    Run context (Expectation expectation) ->
      case expectation context of
        Complete verdict ->
          ( model, Done verdict )
        Inquire message handler ->
          ( { inquiryHandler = handler }
          , Send <| Message.inquiry message
          )
    HandleInquiry message ->
      ( model
      , Done <| handleInquiry message model.inquiryHandler
      )


handleInquiry : Message -> (Message -> Judgment model) -> Verdict
handleInquiry message handler =
  Message.decode Message.inquiryDecoder message
    |> Maybe.map .message
    |> Maybe.map handler
    |> Maybe.map (\judgment ->
      case judgment of
        Complete verdict ->
          verdict
        Inquire _ _ ->
          Claim.Reject <| Report.note "Recursive Inquiry not supported!"
    )
    |> Maybe.withDefault (Claim.Reject <| Report.note "Unable to decode inquiry result!")