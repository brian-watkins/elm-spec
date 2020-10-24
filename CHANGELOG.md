# Changelog

## 10.24.2020
- elm-spec 3.1.0
- elm-spec-core 7.0.0
- elm-spec-runner 2.1.0
- karma-elm-spec-runner 1.6.0

### Added
- elm-spec-runner prints duration of spec suite run
- elm-spec-runner can run scenarios in parallel

### Fixed
- Run animation frames after each step, including the step that runs the initial command.
- Reject scenarios that have extra animation frame tasks; use `Spec.Time.allowExtraAnimationFrames` and
`Spec.Time.nextAnimationFrame` to address.
- Updated dependencies


## 9.10.2020
- elm-spec 3.0.2

### Fixed
- Documentation


## 7.3.2020
- elm-spec 3.0.1

### Fixed
- Cmd values sent from the program's init function that examine the DOM (ie Browser.Dom.getViewport)
are processed as expected.
- Port messages and File downloads are observed in the order they occurred.


## 5.27.2020
- elm-spec 3.0.0
- elm-spec-core 6.0.0
- elm-spec-runner 2.0.0
- karma-elm-spec-runner 1.5.0

### Added
- elm-spec-runner incorporates [Playwright](https://github.com/microsoft/playwright) to allow
specs to be run in a real browser.
- elm-spec-runner now can watch files for changes.
- elm-spec-runner can skip scenarios.
- Scenarios can select and work with files and observe downloads.
- Scenarios can stub or observe HTTP requests that involve files or binary data.
- Scenarios can observe multipart HTTP requests.

### Revised
- To accomodate multipart requests, revised the API in `Spec.Http` for making claims
about HTTP requests.
- `Spec.Claim.require` is now `Spec.Claim.specifyThat`
- Changed `Spec.Witness` to make it way more flexible.
- Moved functions for simulating and observing behavior related to the Browser,
including navigation, to `Spec.Navigator` and removed `Spec.Markup.Navigation`.

------

See Releases for info on earlier releases.
