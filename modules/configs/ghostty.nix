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

    keybind = "global:ctrl+grave_accent=toggle_quick_terminal";

    confirm-close-surface = false;
    quit-after-last-window-closed = true;

    clipboard-read = "allow";
    clipboard-write = "allow";
    clipboard-trim-trailing-spaces = true;
    copy-on-select = "clipboard";

    theme = "light:Monokai Pro Light,dark:Everforest Dark Hard";
    cursor-style = "block";
    cursor-invert-fg-bg = true;
    cursor-opacity = 0.7;
    cursor-style-blink = false;
    mouse-hide-while-typing = true;
    background-opacity = 0.95;
    background-opacity-cells = true;
    background-blur = 20;
    font-family = fonts.mono;
    font-size = fonts.size;
    font-thicken = true;
    font-thicken-strength = 255;
    font-feature = "+zero,-liga,-calt";
    adjust-cell-height = "10%";

    macos-option-as-alt = "right";
    macos-titlebar-style = "hidden";
    macos-icon = "retro";
    macos-icon-frame = "plastic";
    shell-integration = "fish";
    shell-integration-features = "no-cursor";

    window-padding-x = 2;
    window-padding-y = 2;
    window-padding-balance = true;

    quick-terminal-position = "right";
    quick-terminal-animation-duration = 0;

    resize-overlay = "never";
  };
}
