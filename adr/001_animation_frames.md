# Run animation frame after each step

## Status: Accepted

## Context
The Elm runtime uses `requestAnimationFrame` to keep the view updated. In order to
run faster specs, elm-spec uses [@simon/fake-timers](https://github.com/sinonjs/fake-timers)
to fake the `requestAnimationFrame` function (along with other timers). This provides
elm-spec with control over when to run this function, and thus when to update the view.

However, things are a little more complicated than they might seem. It turns out that the
Elm runtime also uses `requestAnimationFrame` during some commands that involve the DOM,
in particular those like `Browser.Dom.getElement` in the `Browser.Dom` module. This means
that sometimes a step might actually need multiple animation frames to complete and update
the view as expected. This gets complicated when a program uses the `Browser.Events.onAnimationFrame`
subscription, which sends an update message on each animation frame.

Previously, elm-spec would run the next animation frame before any step or observer that
touched the DOM (so that the view was updated for that step), and attempt to continue to
run animation frame tasks until none remained at the end of that step. This was a little weird,
and had to try and only run *newly added* tasks so that the spec would not go into an
infinite loop -- since the task that updates the view and the task that listens for
animation frames each add a new request for the next animation frame when they are run.

One major problem with this approach is that sometimes a program might need to run the next
animation frame even if the step itself doesn't touch the DOM. For example, if `Browser.Dom.getElement`
is called when a port message is received, and the spec wants to see that the size of the
element is retrieved and sent out on another port or something. The step and observer just
involves Ports but an animation frame needs to run for the command to complete.

There also exists `Spec.Time.nextAnimationFrame` for manually running the next animation frame.
However, in the case described, something would happen where even that wouldn't trigger the
expected behavior. And in any case, this would actually continue to run animation frames if
they were added in the process of execiting a command, and so probably should have been called
'runAnimationFramesUntilComplete' or something.


## Decision
Elm-spec will run an animation frame (or try to) at the *end* of each spec step, no matter what,
including the step that runs the initial command. And it will *only* run one animation frame.
If any extra animation frame tasks are detected (that is, if there is more than one remaining
animation frame task, which is the view animator), then the scenario will be rejected with a
message explaining that one of the steps triggers extra animation frames.

In order to prevent the scenario from being rejected, one needs to add `Spec.Time.allowExtraAnimationFrames`
to the setup section of the scenario. The point of this really is just to let people know that
something funny could be going on. One can then use `Spec.Time.nextAnimationFrame` to
run single animation frames until one triggers the behavior one wants.

This seems to work much better. First, many common scenarios will just work as expected. If,
for example, one triggers a `Browser.Dom.getElement` command based on some step that just
simulates receiving a port message, then that will just work as expected since the animation frame
will be run at the end of the step -- this will update the view and also run the `getElement`
command. 

Second, in the case of more complicated scenarios involving DOM commands that trigger other
DOM commands or `Browser.Events.onAnimationFrame` the spec writer will be alerted to the fact
that things are complicated, and will have full control over how many animation frames to
execute.


## Consequences
Standard scenarios (ones that do not involve extra animation frame tasks) do not seem to be
affected by this change.

One downside is that in certain cases some implementation details of the Elm runtime will leak
into the scenario script -- especially those involving DOM commands that might need an
extra animation frame to run. However, these cases are probably rare.
