{lib, ...}: let
  hotkey = binding: id: {inherit binding id;};
  unassigned = map (hotkey "Unassigned");
  numberedHotkeys = count: makeHotkeys:
    builtins.concatMap makeHotkeys (lib.range 1 count);
in {
  programs.omniwm = {
    enable = true;

    settings = {
      monitorBarOverrides = [
        {
          id = "D616BC4C-A3B6-4710-874F-0D8CA9954862";
          monitorDisplayUUID = "37D8832A-2D66-02CA-B9F7-8F30A301B230";
          enabled = true;
          notchMode = "splitActiveLeft";
          notchActiveZoneWidth = 90.0;
          hideEmptyWorkspaces = true;
          monitorName = "Built-in Retina Display";
          yOffset = 4;
        }
      ];
      monitorDwindleOverrides = [];
      monitorGapOverrides = [];
      monitorNiriOverrides = [];
      monitorOrientationOverrides = [];
      schemaVersion = 3;

      appearance.mode = "automatic";

      borders = {
        enabled = false;
        width = 5.0;
        color = {
          alpha = 1.0;
          blue = 0.501;
          green = 0.752;
          red = 0.654;
        };
      };

      clipboard = {
        historyEnabled = false;
        maxItems = 1;
        maxItemBytes = 8388608;
        maxTotalBytes = 8388608;
      };

      dwindle = {
        defaultSplitRatio = 1.0;
        moveToRootStable = true;
        singleWindowFit = "fill";
        smartSplit = false;
        splitWidthMultiplier = 1.0;
        useGlobalGaps = true;
      };

      focus = {
        followsMouse = true;
        followsWindowToMonitor = true;
        lockModifier = "rightCommand";
        crossesMonitorAtEdge = false;
        moveCrossesMonitorAtEdge = false;
        moveMouseToFocusedWindow = false;
        raiseOnMouseFocus = false;
      };

      gaps = {
        fullscreenUsesOuterGaps = false;
        size = 16.0;
        outer = {
          bottom = 0.0;
          left = 0.0;
          right = 0.0;
          top = 0.0;
        };
      };

      general = {
        animationsEnabled = true;
        defaultLayoutType = "niri";
        hotkeysEnabled = true;
        hyperKeyModifiers = "Control+Option+Shift+Command";
        ipcEnabled = true;
        preventSleepEnabled = false;
        systemHyperTrigger = "None";
        updateChecksEnabled = true;
      };

      gestures = {
        fingerCount = 3;
        invertDirection = true;
        mouseMoveModifierKey = "option";
        mouseResizeModifierKey = "option";
        scrollEnabled = true;
        scrollModifierKey = "optionShift";
        scrollSensitivity = 5.0;
        trackpadScrollStyle = "snap";
        workspaceSwipeAxis = "vertical";
        workspaceSwipeEnabled = false;
        workspaceSwipeFingerCount = 3;
      };

      hiddenBar = {
        enabled = true;
        hiddenBundleIDs = [];
        rehideIntervalSeconds = 5.0;
      };

      mouseWarp = {
        constrainToArrangement = false;
        enabled = true;
        margin = 1;
      };

      niri = {
        alwaysCenterSingleColumn = false;
        centerFocusedColumn = "never";
        containerPrimarySpanPresets = [
          0.3333333333333333
          0.5
          0.6666666666666666
        ];
        defaultContainerPrimarySpan = 0.5;
        infiniteLoop = false;
        singleWindowFit = "fill";
        visibleContainerCount = 2;
      };

      overview = {
        zoom = 1.0;
        backdrop = {
          alpha = 0.3;
          blue = 0.08;
          green = 0.05;
          red = 0.05;
        };
        windowBorders = {
          hovered = {
            alpha = 1.0;
            blue = 1.0;
            green = 0.6;
            red = 0.4;
          };
          normal = {
            alpha = 0.5;
            blue = 0.35;
            green = 0.3;
            red = 0.3;
          };
          selected = {
            alpha = 1.0;
            blue = 0.4;
            green = 0.8;
            red = 0.3;
          };
        };
      };

      quakeTerminal = {
        animationDuration = 0.2;
        autoHide = false;
        backgroundBlurRadius = 0;
        backgroundEffect = "standardBlur";
        enabled = true;
        heightPercent = 50.0;
        monitorMode = "focusedWindow";
        opacity = 1.0;
        position = "center";
        widthPercent = 50.0;
      };

      routing = {
        arrangements = [];
        mode = "macOS";
      };

      scratchpads.labels = {};

      statusBar = {
        showAppNames = false;
        showWorkspaceName = false;
        useWorkspaceId = false;
      };

      workspaceBar = {
        backgroundOpacity = 0.1;
        deduplicateAppIcons = false;
        enabled = true;
        excludedBundleIDs = [];
        height = 24.0;
        hideEmptyWorkspaces = false;
        hideInNativeFullscreen = false;
        notchActiveZoneWidth = 180.0;
        notchMode = "moveBelowMenuBar";
        position = "overlappingMenuBar";
        reserveLayoutSpace = false;
        revealHoldMilliseconds = 200.0;
        revealModifier = "off";
        showFloatingWindows = false;
        showLabels = true;
        systemStatsButton = false;
        windowLevel = "popup";
        xOffset = 0.0;
        yOffset = 0.0;
        iconOverrides = {};
      };

      appRules = [
        {
          bundleId = "com.cron.electron";
          appNameSubstring = "Calendar";
          assignToWorkspace = "5";
        }
        {
          bundleId = "com.tinyspeck.slackmacgap";
          assignToWorkspace = "6";
        }
        {
          bundleId = "com.tinyspeck.slackmacgap";
          titleRegex = "^(?!(Activity|Later|Threads|Unread Messages|Huddles|Drafts & sent) -)[^()]+ - Culture Amp - Slack$";
          layout = "float";
          assignToWorkspace = "6";
        }
      ];

      hotkeys =
        numberedHotkeys 10 (number: [
          (hotkey "Unassigned" "toggleScratchpad.${toString number}")
          (hotkey "Unassigned" "assignFocusedWindowToScratchpad.${toString number}")
        ])
        ++ numberedHotkeys 9 (number: let
          index = number - 1;
          switchBinding =
            if number <= 7
            then "Option+${toString number}"
            else "Unassigned";
          moveBinding =
            if number <= 7
            then "Option+${builtins.elemAt ["Q" "W" "E" "R" "T" "Y" "U"] index}"
            else "Unassigned";
        in [
          (hotkey switchBinding "switchWorkspace.${toString index}")
          (hotkey moveBinding "moveToWorkspace.${toString index}")
        ])
        ++ numberedHotkeys 9 (number: [
          (hotkey "Unassigned" "switchWorkspaceSlot.${toString number}")
          (hotkey "Unassigned" "moveToWorkspaceSlot.${toString number}")
        ])
        ++ [
          (hotkey "Option+Tab" "workspaceBackAndForth")
        ]
        ++ unassigned [
          "switchWorkspace.next"
          "switchWorkspace.previous"
        ]
        ++ [
          (hotkey "Option+H" "focus.left")
          (hotkey "Option+J" "focus.down")
          (hotkey "Option+K" "focus.up")
          (hotkey "Option+L" "focus.right")
        ]
        ++ unassigned [
          "focusPrevious"
          "focusDownOrLeft"
          "focusUpOrRight"
          "focusWindowTop"
          "focusWindowBottom"
          "focusWindowDownOrTop"
          "focusWindowUpOrBottom"
          "focusWindowOrWorkspaceDown"
          "focusWindowOrWorkspaceUp"
          "centerVisibleColumns"
        ]
        ++ [
          (hotkey "Option+C" "centerColumn")
          (hotkey "Control+Option+Shift+Up Arrow" "moveWindowToWorkspaceUp")
          (hotkey "Control+Option+Shift+Down Arrow" "moveWindowToWorkspaceDown")
          (hotkey "Control+Option+Shift+Page Up" "moveColumnToWorkspaceUp")
          (hotkey "Control+Option+Shift+Page Down" "moveColumnToWorkspaceDown")
        ]
        ++ (map (index: hotkey "Unassigned" "moveColumnToWorkspace.${toString index}") (lib.range 0 8))
        ++ [
          (hotkey "Option+Shift+H" "move.left")
          (hotkey "Option+Shift+J" "move.down")
          (hotkey "Option+Shift+K" "move.up")
          (hotkey "Option+Shift+L" "move.right")
        ]
        ++ unassigned [
          "moveWindowDown"
          "moveWindowUp"
          "moveWindowDownOrToWorkspaceDown"
          "moveWindowUpOrToWorkspaceUp"
          "consumeWindowIntoColumn"
          "expelWindowFromColumn"
        ]
        ++ [
          (hotkey "Control+Command+Tab" "focusMonitorNext")
          (hotkey "Unassigned" "focusMonitorPrevious")
          (hotkey "Control+Command+Grave" "focusMonitorLast")
        ]
        ++ unassigned [
          "moveWorkspaceToMonitor.left"
          "moveWorkspaceToMonitor.right"
          "moveWorkspaceToMonitor.up"
          "moveWorkspaceToMonitor.down"
          "moveWindowToMonitor.left"
          "moveWindowToMonitor.right"
          "moveWindowToMonitor.up"
          "moveWindowToMonitor.down"
          "toggleColumnTabbed"
        ]
        ++ [
          (hotkey "Option+Return" "toggleFullscreen")
          (hotkey "Unassigned" "toggleNativeFullscreen")
          (hotkey "Control+Option+Shift+Left Arrow" "moveColumn.left")
          (hotkey "Control+Option+Shift+Right Arrow" "moveColumn.right")
          (hotkey "Unassigned" "moveColumn.up")
          (hotkey "Unassigned" "moveColumn.down")
          (hotkey "Control+Option+Home" "moveColumnToFirst")
          (hotkey "Control+Option+End" "moveColumnToLast")
          (hotkey "Option+Home" "focusColumnFirst")
          (hotkey "Option+End" "focusColumnLast")
        ]
        ++ numberedHotkeys 9 (number: [
          (hotkey "Control+Option+${toString number}" "focusColumn.${toString (number - 1)}")
        ])
        ++ (map (number: hotkey "Unassigned" "focusWindowInColumn.${toString number}") (lib.range 1 9))
        ++ (map (number: hotkey "Unassigned" "moveColumnToIndex.${toString number}") (lib.range 1 9))
        ++ [
          (hotkey "Option+Period" "cycleSizeForward")
          (hotkey "Option+Comma" "cycleSizeBackward")
        ]
        ++ unassigned [
          "cycleWindowPrimarySpanForward"
          "cycleWindowPrimarySpanBackward"
          "cycleWindowSecondarySpanForward"
          "cycleWindowSecondarySpanBackward"
        ]
        ++ [
          (hotkey "Option+Shift+F" "toggleContainerFullPrimarySpan")
          (hotkey "Control+Option+F" "expandContainerToAvailablePrimarySpan")
          (hotkey "Control+Option+R" "resetWindowSecondarySpan")
          (hotkey "Option+Minus" "setContainerPrimarySpan.decrease10Percent")
          (hotkey "Option+Equal" "setContainerPrimarySpan.increase10Percent")
          (hotkey "Unassigned" "setWindowPrimarySpan.decrease10Percent")
          (hotkey "Unassigned" "setWindowPrimarySpan.increase10Percent")
          (hotkey "Option+Shift+Minus" "setWindowSecondarySpan.decrease10Percent")
          (hotkey "Option+Shift+Equal" "setWindowSecondarySpan.increase10Percent")
          (hotkey "Option+0" "balanceSizes")
        ]
        ++ unassigned [
          "moveToRoot"
          "toggleSplit"
          "swapSplit"
          "resizeGrow.horizontal"
          "resizeGrow.vertical"
          "resizeShrink.horizontal"
          "resizeShrink.vertical"
          "resizeFocusedWindow.grow"
          "resizeFocusedWindow.shrink"
          "preselect.left"
          "preselect.right"
          "preselect.up"
          "preselect.down"
          "preselectClear"
        ]
        ++ [
          (hotkey "Control+Option+Space" "openCommandPalette")
          (hotkey "Option+Shift+R" "raiseAllFloatingWindows")
          (hotkey "Unassigned" "rescueOffscreenWindows")
          (hotkey "Unassigned" "toggleFocusedWindowFloating")
          (hotkey "Unassigned" "closeFocusedWindow")
          (hotkey "Control+Option+M" "openMenuAnywhere")
          (hotkey "Unassigned" "toggleWorkspaceBarVisibility")
          (hotkey "Unassigned" "toggleHiddenBarPanel")
          (hotkey "Option+Grave" "toggleQuakeTerminal")
          (hotkey "Option+Shift+W" "toggleWorkspaceLayout")
          (hotkey "Option+Shift+O" "toggleOverview")
          (hotkey "Unassigned" "toggleSystemStats")
        ];

      workspaces = [
        {
          id = "AD36F001-C57E-41A5-AC1D-DF5249D007F0";
          layoutType = "niri";
          name = "1";
          monitorAssignment.type = "main";
        }
        {
          id = "B2FAC9D7-93B6-49FE-9B3D-722838B9A9BE";
          layoutType = "niri";
          name = "2";
          monitorAssignment.type = "main";
        }
        {
          id = "BEB842B5-E894-4791-9FD1-397C3CDD3538";
          layoutType = "niri";
          name = "3";
          monitorAssignment.type = "main";
        }
        {
          id = "248AA883-2261-4D45-943C-79C0E46A232B";
          layoutType = "niri";
          name = "4";
          monitorAssignment.type = "main";
        }
        {
          id = "8B8C45D6-CE9E-41D9-BD50-BE4989D5E3DE";
          layoutType = "niri";
          name = "5";
          monitorAssignment.type = "secondary";
        }
        {
          id = "5953F2BF-A378-4266-91B2-287174C4FA4D";
          layoutType = "niri";
          name = "6";
          monitorAssignment.type = "secondary";
        }
        {
          id = "A7D5E104-6985-4516-8ED5-07F144F2A33D";
          layoutType = "niri";
          name = "7";
          monitorAssignment.type = "secondary";
        }
      ];
    };
  };
}
