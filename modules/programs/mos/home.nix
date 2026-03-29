{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.nixfiles.programs.mos.enable {
  home.packages = [pkgs.mos];

  home.activation.mosDefaults = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD /usr/bin/defaults write com.caldis.Mos smooth -bool true
    $DRY_RUN_CMD /usr/bin/defaults write com.caldis.Mos smoothHorizontal -bool true
    $DRY_RUN_CMD /usr/bin/defaults write com.caldis.Mos smoothVertical -bool true
    $DRY_RUN_CMD /usr/bin/defaults write com.caldis.Mos smoothSimTrackpad -bool false

    $DRY_RUN_CMD /usr/bin/defaults write com.caldis.Mos reverse -bool true
    $DRY_RUN_CMD /usr/bin/defaults write com.caldis.Mos reverseHorizontal -bool true
    $DRY_RUN_CMD /usr/bin/defaults write com.caldis.Mos reverseVertical -bool true

    $DRY_RUN_CMD /usr/bin/defaults write com.caldis.Mos speed -float 2.7
    $DRY_RUN_CMD /usr/bin/defaults write com.caldis.Mos step -float 33.6
    $DRY_RUN_CMD /usr/bin/defaults write com.caldis.Mos duration -float 4.35
    $DRY_RUN_CMD /usr/bin/defaults write com.caldis.Mos deadZone -int 1

    $DRY_RUN_CMD /usr/bin/defaults write com.caldis.Mos hideStatusItem -bool false
    $DRY_RUN_CMD /usr/bin/defaults write com.caldis.Mos allowlist -bool false
    $DRY_RUN_CMD /usr/bin/defaults write com.caldis.Mos updateCheckOnAppStart -bool false
    $DRY_RUN_CMD /usr/bin/defaults write com.caldis.Mos updateIncludingBetaVersion -bool false
  '';
}
