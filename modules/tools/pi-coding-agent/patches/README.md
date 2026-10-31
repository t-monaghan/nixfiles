# Question program status

Pi 1.4.0 reports built-in dialogs through OSC 7501, but `ctx.ui.custom()` cannot declare that it waits for user input. `pi-question` 0.5.6 uses `ctx.ui.custom()`.

- `custom-ui-program-status.patch` adds an optional `blocked` value to custom UI options. Pi manages the status through its existing `ProgramStatusReporter`. Closing or cancelling a question restores the current program status. Custom UI without `blocked` keeps its existing behavior.
- `question-program-status.patch` sets `blocked: { kind: "question", message: params.question }` for the question component.

`overlay.nix` applies the Pi patch and runs the program status and dialog tests during the build. `question.nix` pins and patches the npm package. Pi loads this package from the Nix store; it does not modify the npm installation in the home directory.

After activating the configuration, start a new Pi process. A pending question must report `state=blocked`, `app=pi`, and `kind=question`. Its `msg` field contains the base64-encoded question. Answering or cancelling the question must restore `working` until the agent settles.

Remove these patches and restore the npm package setting when upstream Pi and `pi-question` provide this behavior.
