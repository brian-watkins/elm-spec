# Remote Browsers

Typically, the elm-spec-runner controls the browser that serves as the
environment for running specs. When we use JSDOM or Playwright, it's
elm-spec-runner that starts and manages the browser instance.

This approach makes things very simple but isn't always ideal. For example,
if someone is doing development inside a docker container, it can be
annoying to install all the dependencies for Playwright, not to mention
the drag on performance or trickiness around exporting the display to
debug tests.

In addition, someone might want to run elm-spec specs in a browser that
is not supported by Playwright, or in a browser on another device.


### Decision

We will create a new `remote` browser type in which elm-spec-runner exposes
a URL. When someone visits that URL in a browser, the spec suite will run,
with output printed to the command line like normal.

In order to get this to work, we need to do a few things:

1. Start a server that can serve some static and dynamic assets: an index
page that loads any scripts, the compiled specs, any specified css files, etc.
2. Open a websocket connection from the browser to the server. This allows
the browser to stream back results to feed to the reporter, as well as receive
messages from the server.
3. Implement file loading via a URL request for those specs that need file
loading capabilities.
4. Serve any css files that are specified on the command line. We use a template
to insert these into the index file.

Hopefully, this should allow greater flexibility in running elm-spec spec suites.