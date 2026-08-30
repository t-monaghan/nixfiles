{...}: {
  services.home-assistant = {
    enable = true;

    extraComponents = [
      "default_config"
      "mobile_app"
      "esphome"
      "mqtt"
      "cast"
      "rest"
      "matter"
      "thread"
      "otbr"
      "wiim"
    ];

    config = {
      default_config = {};

      homeassistant = {
        name = "Home";
        unit_system = "metric";
        time_zone = "Australia/Melbourne";
      };
      rest = import ./home-assistant/rest.nix;
    };
    # extraPackages = python3Packages: with python3Packages; [ ];
    # HACS-style extras, managed declaratively from nixpkgs:
    # customComponents = with pkgs.home-assistant-custom-components; [ ];
    # customLovelaceModules = with pkgs.home-assistant-custom-lovelace-modules; [ ];
  };

  users.users.hass.extraGroups = ["dialout"];
}
