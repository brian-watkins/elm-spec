module Spec.Http.Contract exposing
  ( Contract
  , openApiV2
  , openApiV3
  , use
  )

import Spec.Setup as Setup exposing (Setup)
import Spec.Setup.Internal as Setup
import Spec.Message as Message exposing (Message)
import Json.Encode as Encode


type Contract =
  OpenApi OpenApiVersion String


type OpenApiVersion
  = V2
  | V3


openApiV2 : String -> Contract
openApiV2 =
  OpenApi V2


openApiV3 : String -> Contract
openApiV3 =
  OpenApi V3


use : List Contract -> Setup model msg -> Setup model msg
use contracts =
  Setup.configurationRequest <| httpContractMessage contracts


httpContractMessage : List Contract -> Message
httpContractMessage contracts =
  Message.for "_http" "contracts"
    |> Message.withBody (Encode.object
      [ ("contracts", Encode.list encodeContract contracts)
      ]
    )


encodeContract : Contract -> Encode.Value
encodeContract contract =
  case contract of
    OpenApi version path ->
      Encode.object
        [ ( "version", encodeOpenApiVersion version )
        , ( "path", Encode.string path )
        ]


encodeOpenApiVersion : OpenApiVersion -> Encode.Value
encodeOpenApiVersion version =
  case version of
    V2 -> Encode.string "2"
    V3 -> Encode.string "3"