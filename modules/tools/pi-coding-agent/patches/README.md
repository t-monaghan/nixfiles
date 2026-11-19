# Question program status

Pi 1.5.2 supports the `blocked` option in `ctx.ui.custom()` and reports it through OSC 7501. The local Pi patch is no longer needed. `pi-question` 0.5.6 uses `ctx.ui.custom()` but does not set this option.

`question-program-status.patch` sets `blocked: { kind: "question", message: params.question }` for the question component. Pi manages the status through its existing `ProgramStatusReporter`. Closing or cancelling a question restores the current program status.

`overlay.nix` provides the `pi-question` package. `question.nix` pins and patches the npm package. Pi loads this package from the Nix store; it does not modify the npm installation in the home directory.

After activating the configuration, start a new Pi process. A pending question must report `state=blocked`, `app=pi`, and `kind=question`. Its `msg` field contains the base64-encoded question. Answering or cancelling the question must restore `working` until the agent settles.

Remove the remaining patch and restore the npm package setting when upstream `pi-question` sets the `blocked` option.
