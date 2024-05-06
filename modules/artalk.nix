{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.artalk;
in
{

  meta = {
    maintainers = with lib.maintainers; [ moraxyc ];
  };

  options = {
    services.artalk = {
      enable = lib.mkEnableOption "artalk, a comment system";
      configFile = lib.mkOption {
        type = lib.types.str;
        default = "/etc/artalk/config.yml";
        description = "Artalk config file path. If it is not exist, Artalk will generate one.";
      };
      workdir = lib.mkOption {
        type = lib.types.str;
        default = "/var/lib/artalk";
        description = "Artalk working directory";
      };
      listenHost = lib.mkOption {
        type = lib.types.str;
        default = "0.0.0.0";
        description = "Artalk listen address";
      };
      listenPort = lib.mkOption {
        type = lib.types.port;
        default = 23366;
        description = "Artalk listen port";
      };
      user = lib.mkOption {
        type = lib.types.str;
        default = "artalk";
        description = "Artalk user name.";
      };

      group = lib.mkOption {
        type = lib.types.str;
        default = "artalk";
        description = "Artalk group name.";
      };

      package = lib.mkPackageOption pkgs "artalk" { };
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.artalk = lib.optionalAttrs (cfg.user == "artalk") {
      description = "artalk user";
      isSystemUser = true;
      group = cfg.group;
    };
    users.groups.artalk = lib.optionalAttrs (cfg.group == "artalk") { };

    environment.systemPackages = [ cfg.package ];

    systemd.services.artalk = {
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      preStart = ''
        umask 0077
        [ -e "${cfg.configFile}" ] || ${cfg.package}/bin/Artalk gen config "${cfg.configFile}"
      '';
      serviceConfig = {
        User = cfg.user;
        Group = cfg.group;
        Type = "simple";
        ExecStart = "${cfg.package}/bin/Artalk server --config ${cfg.configFile} --workdir ${cfg.workdir} --host ${cfg.listenHost} --port ${builtins.toString cfg.listenPort}";
        Restart = "on-failure";
        RestartSec = "5s";
        ConfigurationDirectory = [ "artalk" ];
        StateDirectory = [ "artalk" ];
        AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
      };
    };
  };
}
