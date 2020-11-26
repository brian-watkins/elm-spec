# Changelog

## 11.25.2020
- elm-spec-core 7.1.3
- elm-spec-runner 2.1.4
- karma-elm-spec-framework 1.6.4

### Fixed
- When using `Spec.Markup.Event.trigger` to simulate an event, the event object can set properties
under the `target` attribute.


## 10.29.2020
- elm-spec-core 7.1.2
- elm-spec-runner 2.1.3
- karma-elm-spec-framework 1.6.3

### Fixed
- View updates as expected when the final step of a scenario triggers a task
that waits on the next animation frame.


## 10.27.2020
- elm-spec-core 7.1.1
- elm-spec-runner 2.1.2
- karma-elm-spec-framework 1.6.2

### Fixed
- View updates as expected when setup the scenario at a particular time via `Spec.Time.withTime`


## 10.25.2020
- elm-spec-core 7.1.0
- elm-spec-runner 2.1.1
- karma-elm-spec-framework 1.6.1

### Added
- Compiler provides info on status of last compile

### Fixed
- elm-spec-runner prints compilation failure messages correctly once again


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
