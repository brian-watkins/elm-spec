module Spec.Program exposing
  ( SpecProgram
  , fragment
  , withModel
  , worker
  , withInit
  , withSubscriptions
  )


type alias SpecProgram model msg =
  { update: msg -> model -> ( model, Cmd msg )
  , init: () -> ( model, Cmd msg )
  , subscriptions: model -> Sub msg
  }


type alias SpecInit model msg =
  { init: () -> ( model, Cmd msg )
  , subscriptions: model -> Sub msg
  }


type alias SpecState model =
  () -> model


fragment : (msg -> model -> ( model, Cmd msg )) -> SpecState model -> SpecProgram model msg
fragment fragmentUpdate specState =
  { update = fragmentUpdate
  , init = \_ -> ( specState (), Cmd.none )
  , subscriptions = \_ -> Sub.none
  }


worker : (msg -> model -> ( model, Cmd msg )) -> SpecInit model msg -> SpecProgram model msg
worker programUpdate specInit =
  { update = programUpdate
  , init = specInit.init
  , subscriptions = specInit.subscriptions
  }


withSubscriptions : (model -> Sub msg) -> SpecInit model msg -> SpecInit model msg
withSubscriptions programSubscriptions specInit =
  { specInit | subscriptions = programSubscriptions }


withInit : (() -> ( model, Cmd msg )) -> () -> SpecInit model msg
withInit initGenerator _ =
  { init = initGenerator
  , subscriptions = \_ -> Sub.none
  }


withModel : (() -> model) -> () -> SpecState model
withModel modelGenerator _ =
  modelGenerator
