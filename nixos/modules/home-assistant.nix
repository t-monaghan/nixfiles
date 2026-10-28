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
      "smlight"
      "androidtv_remote"
      "linkplay"
    ];

    config = {
      default_config = {};
      # Load automations saved by the Home Assistant UI.
      automation = "!include automations.yaml";
      scene = "!include scenes.yaml";

      homeassistant = {
        name = "Home";
        unit_system = "metric";
        time_zone = "Australia/Melbourne";
      };
      rest = import ./home-assistant/rest.nix;
      template = [
        {
          switch = [
            {
              name = "Lounge and Kitchen";
              unique_id = "lounge_and_kitchen";
              state = ''
                {{ is_state('light.living_room_dome', 'on')
                   or is_state('light.living_room_paper_lamp_2', 'on')
                   or is_state('switch.kitchen_power_plug', 'on') }}
              '';
              turn_on = [
                {
                  action = "homeassistant.turn_on";
                  target.entity_id = [
                    "light.living_room_dome"
                    "light.living_room_paper_lamp_2"
                    "switch.kitchen_power_plug"
                  ];
                }
              ];
              turn_off = [
                {
                  action = "homeassistant.turn_off";
                  target.entity_id = [
                    "light.living_room_dome"
                    "light.living_room_paper_lamp_2"
                    "switch.kitchen_power_plug"
                  ];
                }
              ];
            }
          ];
        }
      ];
    };
    # extraPackages = python3Packages: with python3Packages; [ ];
    # HACS-style extras, managed declaratively from nixpkgs:
    # customComponents = with pkgs.home-assistant-custom-components; [ ];
    # customLovelaceModules = with pkgs.home-assistant-custom-lovelace-modules; [ ];
  };

  users.users.hass.extraGroups = ["dialout"];
}
