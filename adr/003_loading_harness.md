# Compiling and Loading the Elm-Spec Harness

## Context

Right now, in order to run an elm-spec program, we need to do a few things in a definite order.

At some point, compile the Elm code using the `Compiler` from elm-spec-core. This will
wrap the compiled code so that the parts of the program that interact with the outside world
can be easily faked out. 

Then, to get the program running: First, create an `ElmContext` object. This creates
all the fake objects on the `window`
object that the compiled elm code will attempt to reference. Second, evaluate the compiled
elm code. It doesn't matter when we compile the elm code, of course, just that it is
evaluated in the browser environment *after* we have created a new `ElmContext` in that
environment.

So, it's a little wild, I guess, that simply instantiating an `ElmContext` modifies the `window`
object and so on. 

Part of the need for this comes from the fact that the compiled Elm code is wrapped in an IFFE.
But there's no reason why we actually have to do that ...

We've been able to deal with this problem so far because the only things that need to go
through this process are elm-spec-runner and karma-elm-spec-framework. But with the harness,
we are now asking a test writer to follow this process as well. For that reason, we need to
simplify it so it's not a source of errors.

## Decision

We should change this flow so that we don't need to create an `ElmContext` and evaluate the
compiled Elm code in a particular order.

First, we will wrap the compiled Elm code in a function that takes an `ElmContext`. Evaluating
this code will still attach the `Elm` object to the window (since we're providing it with a
proxy object). But by using a normal function here, we have more control over when the `Elm`
object is loaded.

Then, we need to have `ElmContext` store references to all the fakes inside itself -- there's no
real need to store these on the `window` object. So the only things we need to store on the `window`
are (1) the function to load Elm -- because this is how the compiled Elm code provides the function;
I don't think we can reference it any other way. (2) Data on what the compiler actually
tried to do, like what files it tried to compile, the path and all that; we store this on the window
so it's available as soon as the compiled code is evaluated -- there may be better ways to do this.
And (3) the function for loading files, which has to be a function accessible on the window
anyway (since that's how Playwright and JSDOM allow us to register a function to be executed in Node).

Once we do this, then it turns out that the test writer doesn't need to create an `ElmContext`
at all ... we can have `HarnessController` do that when `prepareHarness` is called. In fact,
we don't even need to bundle anything extra. This will be included in the bundle of tests that
get executed in the browser.

We could also change SuiteRunner to create it's own `ElmContext` as well, but it's not necessary.