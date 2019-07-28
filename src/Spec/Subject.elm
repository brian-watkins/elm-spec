module Spec.Subject exposing
  ( Subject
  , fragment
  , withModel
  , worker
  , configure
  , withInit
  , withSubscriptions
  )

import Spec.Types exposing (..)


type alias Subject model msg =
  { update: msg -> model -> ( model, Cmd msg )
  , init: () -> ( model, Cmd msg )
  , subscriptions: model -> Sub msg
  , configureEnvironment: Cmd (Msg msg)
  }


fragment : (msg -> model -> ( model, Cmd msg )) -> Subject model msg -> Subject model msg
fragment fragmentUpdate specProgram =
  { specProgram | update = fragmentUpdate }


worker : (msg -> model -> ( model, Cmd msg )) -> Subject model msg -> Subject model msg
worker programUpdate specProgram =
  { specProgram | update = programUpdate }


configure : Cmd (Msg msg) -> Subject model msg -> Subject model msg
configure command specProgram =
  { specProgram | configureEnvironment = Cmd.batch [ specProgram.configureEnvironment, command ] }


withSubscriptions : (model -> Sub msg) -> Subject model msg -> Subject model msg
withSubscriptions programSubscriptions specProgram =
  { specProgram | subscriptions = programSubscriptions }


withInit : (() -> ( model, Cmd msg )) -> () -> Subject model msg
withInit initGenerator _ =
  { update = \_ model -> (model, Cmd.none)
  , init = initGenerator
  , subscriptions = \_ -> Sub.none
  , configureEnvironment = Cmd.none
  }


withModel : (() -> model) -> () -> Subject model msg
withModel modelGenerator _ =
  { update = \_ model -> (model, Cmd.none)
  , init = \_ -> ( modelGenerator (), Cmd.none )
  , subscriptions = \_ -> Sub.none
  , configureEnvironment = Cmd.none
  }