# macOS

When you present a shell command for the user to run, ask if the user wants
you to copy it to the clipboard. Run `pbcopy` only after the user confirms.

If Docker fails during an `aws-sandy` task, check `docker info`. On these
Macs, OrbStack provides Docker; ask the user to start OrbStack if it is not
running. See the `aws-sandy` skill for IMDS server recovery steps.
