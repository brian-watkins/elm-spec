module Harness.Errors exposing
  ( notFoundError
  , configurationError
  )

import Spec.Report as Report exposing (Report)


notFoundError : String -> String -> Report
notFoundError elementType name =
  Report.note <| "No " ++ elementType ++ " has been exposed with the name " ++ name


configurationError : String -> String -> String -> Report
configurationError elementType name error =
  Report.note <| "Unable to configure " ++ elementType ++ " '" ++ name ++ "' -- " ++ error