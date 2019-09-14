module Spec.Observation.Internal exposing
  ( Judgment(..)
  , Observation(..)
  , Context
  , Config
  , toProcedure
  )

import Spec.Message as Message exposing (Message)
import Spec.Observer as Observer exposing (Observer, Verdict)
import Spec.Observation.Message as Message
import Procedure exposing (Procedure)
import Procedure.Channel as Channel
import Spec.Observation.Report as Report


type Observation model =
  Observation
    (Context model -> Judgment model)


type alias Context model =
  { model: model
  , effects: List Message
  }


type Judgment model
  = Complete Verdict
  | AndThen Message (Message -> Judgment model)


type alias Config msg a =
  { a
  | send: Message -> Cmd msg
  , listen: (Message -> msg) -> Sub msg
  }


toProcedure : Config msg a -> Context model -> Observation model -> Procedure Never Verdict msg
toProcedure config context (Observation observation) =
  case observation context of
    Complete verdict ->
      Procedure.provide verdict
    AndThen message handler ->
      Channel.open (\key -> config.send <| Message.inquiry key message)
        |> Channel.connect config.listen
        |> Channel.filter (\key data -> filterForInquiryResult key data)
        |> Channel.acceptOne
        |> Procedure.map (\inquiry ->
          Message.decode Message.inquiryDecoder inquiry
            |> Maybe.map .message
            |> Maybe.map handler
            |> Maybe.map (\judgment ->
              case judgment of
                Complete verdict ->
                  verdict
                AndThen _ _ ->
                  Observer.Reject <| Report.note "Recursive Inquiry not supported!"
            )
            |> Maybe.withDefault (Observer.Reject <| Report.note "Unable to decode inquiry result!")
        )


filterForInquiryResult : String -> Message -> Bool
filterForInquiryResult key message =
  if Message.is "_observer" "inquiryResult" message then
    Message.decode Message.inquiryDecoder message
      |> Maybe.map .key
      |> Maybe.map (\actual -> actual == key)
      |> Maybe.withDefault False
  else
    False
