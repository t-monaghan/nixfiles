# Home Assistant for the `dolomite` box.
#
# Add `./home-assistant.nix` to the imports list in configuration.nix.
# UI at http://<box-ip>:8123 after `nixos-rebuild switch`.
# All state (DB, secrets, UI-added integrations) lives in /var/lib/hass and
# persists across rebuilds — only the bits below are declarative.
{
  config,
  lib,
  pkgs,
  ...
}: {
  services.home-assistant = {
    enable = true;

    # Opens TCP 8123 for the web UI on the LAN.
    openFirewall = true;

    # Python integrations to build in. `default_config` is the meta-bundle the
    # onboarding flow expects (frontend, history, logbook, energy, ...).
    # Add one entry per integration you actually use so its deps are available;
    # UI-added integrations still need their component listed here.
    extraComponents = [
      "default_config"
      "met" # default weather provider used during onboarding
      "radio_browser" # onboarding media demo
      "mobile_app" # companion app + push notifications
      "esphome"
      "mqtt"
      "cast" # Google Cast / Nest displays
      "tradfri" # IKEA Trådfri gateway
      # --- device/service specific: uncomment what you have ---
      # "zha" # Zigbee (needs a coordinator dongle; see udev note below)
      "matter"
      "thread"
      "otbr"
      # "hue"
      # "wled"
      # "spotify"
      # "homekit_controller"
    ];

    # Declarative configuration.yaml.
    #
    # NOTE: setting `config` makes configuration.yaml a READ-ONLY store symlink.
    # You can still add integrations/devices/automations via the UI (those live
    # in /var/lib/hass/.storage and stay writable) — you just can't hand-edit
    # YAML on the box. To drive YAML from the UI instead, set `config = null;`
    # (HA writes its own editable file), but keep `extraComponents` either way.
    config = {
      # Pulls in the standard built-ins (frontend, config UI, history, ...).
      default_config = {};

      homeassistant = {
        name = "Home";
        unit_system = "metric"; # or "us_customary"
        time_zone = "Etc/UTC"; # <-- set yours, e.g. "Australia/Melbourne"
        # latitude/longitude/elevation can go here or be set in the UI.
      };

      # Sane defaults; the commented bits are only needed behind a reverse proxy.
      http = {
        server_host = "0.0.0.0";
        use_x_forwarded_for = true;
        trusted_proxies = ["127.0.0.1" "::1"];
      };

      # History is kept in an sqlite DB under /var/lib/hass by default.
      # recorder.purge_keep_days = 30;
    };

    # Extra Python packages for templates/integrations (rarely needed):
    # extraPackages = python3Packages: with python3Packages; [ ];

    # HACS-style extras, managed declaratively from nixpkgs:
    # customComponents = with pkgs.home-assistant-custom-components; [ ];
    # customLovelaceModules = with pkgs.home-assistant-custom-lovelace-modules; [ ];
  };

  # USB Zigbee/Z-Wave coordinator? Give hass serial access and reference the
  # stable /dev/serial/by-id/... path in the integration config:
  users.users.hass.extraGroups = ["dialout"];
}
