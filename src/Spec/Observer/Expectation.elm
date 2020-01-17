module Spec.Observer.Expectation exposing
  ( Model, Msg(..), init, update
  , Judgment(..)
  , Expectation(..)
  , Command(..)
  , Context
  )

import Spec.Message as Message exposing (Message)
import Spec.Claim as Claim exposing (Verdict)
import Spec.Report as Report
import Spec.Observer.Message as Message


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
  case inquiryResult message handler of
    Ok verdict ->
      verdict
    Err err ->
      Claim.Reject <| Report.fact "Unable to decode inquiry result" err


inquiryResult : Message -> (Message -> Judgment model) -> Result String Verdict
inquiryResult message handler =
  Message.decode Message.inquiryDecoder message
    |> Result.map .message
    |> Result.map handler
    |> Result.map (\judgment ->
      case judgment of
        Complete verdict ->
          verdict
        Inquire _ _ ->
          Claim.Reject <| Report.note "Recursive Inquiry not supported!"
    )