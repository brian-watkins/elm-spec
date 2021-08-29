# Harness Waiting Strategy

## Context

We're seeing some things happen with harnes actions.

1. The Observe state starts by sending a message that waits for any existing stack to complete and
then runs an animation frame if necessary. This was done to make a test pass that triggered a
`Browser.Navigation.load` via a port command. The test asserts that the we see the external navigation
screen and that wasn't loading until we waited for an animation frame update.

2. It turns out that `Browser.Navigation.load` needs to send a port message back into the app and this
involves a `setTimeout` call. AND since the `send` function on a port is just a regular function, there's
no wait to wait for things to complete (unlike the harness functions, which we can wait on). So once the
navigation load happens, we send a message back to the program (which will update the view with the external
navigation screen). But that message is processed via `setTimeout(0)` which allows the next function to be
processed, which turns out to be the observation of the screen, which fails since the update hasn't happened yet.
Then the update happens and we can see that the screen has been updated as expected.

3. Another test that shows animation frame tasks being reset between setups failed because it subscribed
to animation frames and *another* animation frame occurs before we observe (because of 1 above). This means
that the behavior for tests witten with the harness differs from the behavior for regular specs, which is
described in [this adr](001_animation_frames.md).

4. We can generalize the problematic case described in (2) I think. Any incoming port message that results in
commands being processed should show the same problem, where subsequent function calls in the test will be processed
even though the activity resulting from the port message has not yet completed. Note that some usages of the
`Spec.File` functions follow a pattern similar to `Browser.Navigation.load` where a message is sent back into
the spec program to signal that something should be recorded and processed.

5. Note that we just noticed this because the test in (2) asserts that after a navigation, the view updates
to show that we've navigated beyond the bounds of the elm program. This isn't really important to assert
upon, I suppose. But because of (4) there are cases where we would expect the view to have updated. So just
ignoring this doesn't seem like a great option. Although maybe we need a better test that demonstrates why
this problem is worth solving.

There are a few options:

1. Don't run an animation frame before the Observe step ... and ignore the problem with the `Navigation.load` test.
But see (5) -- not a good idea.

2. Expose a way to run a function (synchronously) on the program runner. That way, after a `Navigation.load` occurs,
we call this function to immediately (synchronously) run any animation tasks. This will actually make the test pass.
And has the benefit of isolating this change to cases where a `Navigation.load` occurs. But due to (4) above, this
problem is not just distinctive to loading a url ...

3. Really the problem follows from the fact that actions on the Elm program can be triggered by sending a
port message directly during the test -- something that can't happen during a normal Spec and is one of the
main reasons we have the harness in the first place: so that we can describe the interaction between the JS and Elm
parts of a system in one test. So, we could follow the pattern in (2) and run any animation tasks after
each port message is sent from JS. Since we return a proxy for the app, we have a way to run a function before or
after a port message is sent. It turns out that this will make the test pass. But we are limited to only
doing something synchronous here. We can run any queued animation tasks, but we can't wait on subsequent tasks.
So this doesn't feel like a sufficiently general solution. But we need a better test to prove that.

4. Add a `wait` function to the harness object. This will be an async function that either returns immediately or
waits for the stack to complete and then runs any remaining tasks before signaling that it's ok to continue -- just
as happens at the end of every step. This probably would be a general solution -- assuming we're able to call this
function at the right time during a test. But it depends on the test writer realizing what's happening and knowing
to wait on this function to fix things.


## Decision

We will add a `wait` function to the harness object so that a test writer can wait for any actions
triggered by the JS code (by sending a port message into the program) to complete. This seems like the most
general solution.

We will add some information to the docs to try and remind folks to use this function when necessary.