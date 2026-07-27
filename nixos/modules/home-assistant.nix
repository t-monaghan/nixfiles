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
      rest = [
        {
          resource = "http://localhost:1997/tom";
          scan_interval = "1800";
          sensor = [
            {
              name = "toms.spendable";
              value_template = "{{ value_json.spendable }}";
            }
          ];
        }
        {
          resource = "http://localhost:1997/kelsey";
          scan_interval = "1800";
          sensor = [
            {
              name = "kelseys.spendable";
              value_template = "{{ value_json.spendable }}";
            }
          ];
        }
        {
          resource = "http://localhost:1997/joint";
          scan_interval = "1800";
          sensor = [
            {
              name = "joint.spendable";
              value_template = "{{ value_json.spendable }}";
            }
          ];
        }
      ];
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
