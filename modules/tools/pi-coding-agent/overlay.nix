final: prev: {
  pi-coding-agent = prev.pi-coding-agent.overrideAttrs (old: {
    patches = (old.patches or []) ++ [./patches/custom-ui-program-status.patch];
    doCheck = true;
    checkPhase = ''
      runHook preCheck
      npm test --workspace=packages/coding-agent -- \
        test/interactive-mode-custom-program-status.test.ts \
        test/interactive-mode-extension-dialogs.test.ts \
        test/interactive-mode-status.test.ts \
        test/program-status-reporter.test.ts
      runHook postCheck
    '';
  });
  pi-question = final.callPackage ./question.nix {};
}
