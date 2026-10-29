{
  sandy,
  imds-broker,
  ...
}: [
  (final: prev: {
    sandy = sandy.packages.${final.stdenv.hostPlatform.system}.default;
    imds-broker = imds-broker.packages.${final.stdenv.hostPlatform.system}.default;
    # worktrunk 0.68.0 ships shell-detection tests that read the host
    # process table (`test_process_name_and_ppid_self`,
    # `test_probe_reports_invoked_name_for_sh`). The Nix build sandbox on
    # darwin hides other processes, so they panic and fail the build.
    # Skip just those two so the package still builds; the rest of the
    # suite (1371 tests) keeps running.
    worktrunk = prev.worktrunk.overrideAttrs (old: {
      checkFlags =
        (old.checkFlags or [])
        ++ [
          "--skip=shell::utils::tests::test_process_name_and_ppid_self"
          "--skip=shell::utils::tests::test_probe_reports_invoked_name_for_sh"
        ];
    });
  })
]
