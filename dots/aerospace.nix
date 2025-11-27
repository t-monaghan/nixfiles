{
  start-at-login = true;
  enable-normalization-opposite-orientation-for-nested-containers = false;
  enable-normalization-flatten-containers = false;
  default-root-container-orientation = "auto";
  default-root-container-layout = "accordion";
  accordion-padding = 30;
  gaps = {
    inner.horizontal = 15;
    inner.vertical = 15;
    outer.left = 15;
    outer.right = 15;
    outer.top = 15;
    outer.bottom = 15;
  };
  mode.main.binding = {
    "ctrl-alt-j" = "exec-and-forget open -na Ghostty";
    "ctrl-alt-k" = "exec-and-forget open -na Firefox";

    "alt-slash" = "layout tiles horizontal vertical";
    "alt-comma" = "layout accordion horizontal vertical";

    "alt-h" = "focus left";
    "alt-j" = "focus down";
    "alt-k" = "focus up";
    "alt-l" = "focus right";

    "alt-1" = "workspace 1";
    "alt-2" = "workspace 2";
    "alt-3" = "workspace 3";
    "alt-4" = "workspace 4";
    "alt-5" = "workspace 5";
    "alt-6" = "workspace 6";
    "alt-z" = "fullscreen";

    "alt-shift-h" = ["join-with left"];
    "alt-shift-j" = ["join-with down"];
    "alt-shift-k" = ["join-with up"];
    "alt-shift-l" = ["join-with right"];

    "ctrl-cmd-h" = "move left";
    "ctrl-cmd-j" = "move down";
    "ctrl-cmd-k" = "move up";
    "ctrl-cmd-l" = "move right";

    "alt-q" = ["move-node-to-workspace 1" "workspace 1"];
    "alt-w" = ["move-node-to-workspace 2" "workspace 2"];
    "alt-e" = ["move-node-to-workspace 3" "workspace 3"];
    "alt-r" = ["move-node-to-workspace 4" "workspace 4"];
    "alt-t" = ["move-node-to-workspace 5" "workspace 5"];
    "alt-y" = ["move-node-to-workspace 6" "workspace 6"];

    "alt-shift-minus" = "resize smart -200";
    "alt-shift-equal" = "resize smart +200";

    "cmd-tab" = "move-node-to-monitor --wrap-around next";
    "alt-tab" = "workspace-back-and-forth";
    "alt-shift-tab" = "move-workspace-to-monitor --wrap-around next";
  };
  on-window-detected = [
    {
      "if".window-title-regex-substring = "picture-in-picture";
      run = ["layout floating"];
    }
  ];
}
