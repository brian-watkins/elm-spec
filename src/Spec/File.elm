module Spec.File exposing
  ( Download
  , observeDownloads
  , name
  , text
  )

{-| Observe and make claims about files during a spec.

# Observe Downloaded Files
@docs Download, observeDownloads

# Make Claims about Downloaded Files
@docs name, text

-}

import Spec.Observer exposing (Observer)
import Spec.Observer.Internal as Observer
import Spec.Message as Message
import Json.Decode as Json
import Spec.Claim as Claim exposing (Claim)
import Spec.Report as Report


{-| Represents a file downloaded in the course of a scenario.
-}
type Download
  = Download DownloadData


type alias DownloadData =
  { name: String
  , content: String
  }


{-| Observe downloads tha occurred during a scenario.
-}
observeDownloads : Observer model (List Download)
observeDownloads =
  Observer.observeEffects <|
    \messages ->
      List.filter (Message.is "_file" "download") messages
        |> List.filterMap (Result.toMaybe << Message.decode downloadDecoder)


downloadDecoder : Json.Decoder Download
downloadDecoder =
  Json.map2 DownloadData
    (Json.field "name" Json.string)
    (Json.field "content" Json.string)
    |> Json.map Download


{-| Claim that the name of a downloaded file satisfies the given claim.

-}
name : Claim String -> Claim Download
name claim =
  \(Download download) ->
    claim download.name
      |> Claim.mapRejection (\report -> Report.batch
        [ Report.note "Claim rejected for downloaded file name"
        , report
        ]
      )


{-| Claim that the text content of a downloaded file satisfies the given claim.

-}
text : Claim String -> Claim Download
text claim =
  \(Download download) ->
    claim download.content
      |> Claim.mapRejection (\report -> Report.batch
        [ Report.note "Claim rejected for downloaded file text"
        , report
        ]
      )