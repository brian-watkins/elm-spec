# Changelog

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
