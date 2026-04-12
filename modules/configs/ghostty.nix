{...}:
let
  fonts = import ./fonts.nix;
in {
  enable = true;
  package = null;
  enableFishIntegration = true;
  settings = {
    auto-update = "download";
    auto-update-channel = "stable";
    clipboard-read = "allow";
    clipboard-write = "allow";
    clipboard-trim-trailing-spaces = true;
    theme = "light:Monokai Pro Light,dark:Everforest Dark Hard";
    cursor-style = "block";
    cursor-style-blink = false;
    mouse-hide-while-typing = true;
    background-opacity = 0.95;
    background-blur-radius = 20;
    font-family = fonts.mono;
    font-size = fonts.size;
    font-thicken = true;
    adjust-cell-height = "10%";
    macos-titlebar-style = "hidden";
    macos-option-as-alt = true;
    shell-integration = "fish";
    shell-integration-features = "no-cursor";
    window-padding-x = 2;
    window-padding-y = 2;
    window-padding-balance = true;
  };
}
