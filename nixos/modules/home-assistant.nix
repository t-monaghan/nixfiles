{...}: {
  services.home-assistant = {
    enable = true;
    openFirewall = true;

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

      http = {
        server_host = "0.0.0.0";
        use_x_forwarded_for = true;
        trusted_proxies = ["127.0.0.1" "::1"];
      };
    };
    # extraPackages = python3Packages: with python3Packages; [ ];
    # HACS-style extras, managed declaratively from nixpkgs:
    # customComponents = with pkgs.home-assistant-custom-components; [ ];
    # customLovelaceModules = with pkgs.home-assistant-custom-lovelace-modules; [ ];
  };

  users.users.hass.extraGroups = ["dialout"];
}
