module Spec.Program exposing
  ( SpecProgram
  , fragment
  , withModel
  , worker
  , withInit
  )


type alias SpecProgram model msg =
  { update: msg -> model -> ( model, Cmd msg )
  , init: () -> ( model, Cmd msg )
  }


type alias SpecInit model msg =
  () -> ( model, Cmd msg )


type alias SpecState model =
  () -> model


fragment : (msg -> model -> ( model, Cmd msg )) -> SpecState model -> SpecProgram model msg
fragment fragmentUpdate specState =
  { update = fragmentUpdate
  , init = \_ -> ( specState (), Cmd.none )
  }


worker : (msg -> model -> ( model, Cmd msg )) -> SpecInit model msg -> SpecProgram model msg
worker programUpdate specInit =
  { update = programUpdate
  , init = specInit
  }


withInit : (() -> ( model, Cmd msg )) -> () -> SpecInit model msg
withInit initGenerator _ =
  initGenerator


withModel : (() -> model) -> () -> SpecState model
withModel modelGenerator _ =
  modelGenerator
