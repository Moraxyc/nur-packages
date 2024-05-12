{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.services.cyrus-imap;
  cyrus-imapdPkg = pkgs.cyrus-imapd;
  inherit (lib)
    literalExpression
    mkEnableOption
    mkIf
    mkOption
    optionalAttrs
    generators
    mapAttrsToList
    ;
  inherit (lib.strings) concatStringsSep;
  inherit (lib.types)
    attrsOf
    submodule
    listOf
    oneOf
    str
    int
    bool
    ints
    enum
    nullOr
    path
    ;

  mkCyrusConfig =
    settings:
    concatStringsSep "\n  " (
      mapAttrsToList (n: v: v) (
        builtins.mapAttrs (
          name: value:
          concatStringsSep " " (
            [ "${name}" ]
            ++ (mapAttrsToList (
              n: v:
              if (v != null) then
                if builtins.isInt v then
                  "${n}=${builtins.toString v}"
                else
                  "${n}=\"${if builtins.isList v then (concatStringsSep " " v) else v}\""
              else
                ""
            ) value)
          )
        ) settings
      )
    );
  cyrusConfig = ''
    START {
      ${mkCyrusConfig cfg.cyrusSettings.START}
    }
    SERVICES {
      ${mkCyrusConfig cfg.cyrusSettings.SERVICES}
    }
    EVENTS {
      ${mkCyrusConfig cfg.cyrusSettings.EVENTS}
    }
    DAEMON {
      ${mkCyrusConfig cfg.cyrusSettings.DAEMON}
    }
  '';

  imapdConfig =
    with generators;
    toKeyValue {
      mkKeyValue = mkKeyValueDefault {
        mkValueString =
          v:
          if builtins.isBool v then
            if v then "yes" else "no"
          else if builtins.isList v then
            concatStringsSep " " v
          else
            mkValueStringDefault { } v;
      } ": ";
      listsAsDuplicateKeys = false;
    } cfg.imapdSettings;
in
{
  options.services.cyrus-imap = {
    enable = mkEnableOption ("Cyrus IMAP, an email, contacts and calendar server");

    debug = mkEnableOption ("enable debugging on cyrus master");
    listenQueue = mkOption {
      type = int;
      default = 32;
      description = ''
        Socket listen queue backlog size
        See listen(2). Default is 32, you may want to increase this number if you have a very high connection rate
      '';
    };
    tmpDBDir = mkOption {
      type = path;
      default = "/run/cyrus/db";
      description = ''
        Locations for DB files.
        DBs under this directory are recreated upon initialization, so should live in ephemeral storage for best performance.
      '';
    };
    cyrusSettings = mkOption {
      type = submodule {
        options = {
          START = mkOption {
            default = {
              recover = {
                cmd = [
                  "ctl_cyrusdb"
                  "-r"
                ];
              };
            };
            description = ''
              This section lists the processes to run before any SERVICES are spawned. This section is typically used to initialize databases. Master itself will not startup until all tasks in START have completed, so put no blocking commands here.
            '';
          };
          SERVICES = mkOption {
            default = {
              imap = {
                cmd = [ "imapd" ];
                listen = "imap";
                prefork = 0;
              };
              pop3 = {
                cmd = [ "pop3d" ];
                listen = "pop3";
                prefork = 0;
              };
              lmtpunix = {
                cmd = [ "lmtpd" ];
                listen = "/run/cyrus/lmtp";
                prefork = 0;
              };
              notify = {
                cmd = [ "notifyd" ];
                listen = "/run/cyrus/notify";
                proto = "udp";
                prefork = 0;
              };
            };
            description = ''
              This section is the heart of the cyrus.conf file. It lists the processes that should be spawned to handle client connections made on certain Internet/UNIX sockets.
            '';
          };
          EVENTS = mkOption {
            default = {
              tlsprune = {
                cmd = [ "tls_prune" ];
                at = 400;
              };
              delprune = {
                cmd = [
                  "cyr_expire"
                  "-E"
                  "3"
                ];
                at = 400;
              };
              deleteprune = {
                cmd = [
                  "cyr_expire"
                  "-E"
                  "4"
                  "-D"
                  "28"
                ];
                at = 430;
              };
              expungeprune = {
                cmd = [
                  "cyr_expire"
                  "-E"
                  "4"
                  "-X"
                  "28"
                ];
                at = 445;
              };
              checkpoint = {
                cmd = [
                  "ctl_cyrusdb"
                  "-c"
                ];
                period = 30;
              };
            };
            description = ''
              This section lists processes that should be run at specific intervals, similar to cron jobs. This section is typically used to perform scheduled cleanup/maintenance.
            '';
          };
          DAEMON = mkOption {
            default = { };
            description = ''
              This section lists long running daemons to start before any SERVICES are spawned. master(8) will ensure that these processes are running, restarting any process which dies or forks. All listed processes will be shutdown when master(8) is exiting.
            '';
          };
        };
      };
      description = "Cyrus configuration settings. [cyrus.conf(5)](https://www.cyrusimap.org/imap/reference/manpages/configs/cyrus.conf.html)";
    };
    imapdSettings = mkOption {
      type = submodule {
        freeformType = attrsOf (oneOf [
          str
          int
          bool
          (listOf str)
        ]);
        options = {
          configdirectory = mkOption {
            type = path;
            default = "/var/lib/cyrus";
            description = ''
              The pathname of the IMAP configuration directory. This field is required.
            '';
          };
          lmtpsocket = mkOption {
            type = path;
            default = "/run/cyrus/lmtp";
            description = ''
              Unix socket that lmtpd listens on, used by deliver(8). This should match the path specified in cyrus.conf(5).
            '';
          };
          idlesocket = mkOption {
            type = path;
            default = "/run/cyrus/idle";
            description = ''
              Unix socket that idled listens on.
            '';
          };
          notifysocket = mkOption {
            type = path;
            default = "/run/cyrus/notify";
            description = ''
              Unix domain socket that the mail notification daemon listens on.
            '';
          };
        };
      };
      default = {
        admins = [ "cyrus" ];
        allowplaintext = true;
        defaultdomain = "localhost";
        defaultpartition = "default";
        duplicate_db_path = "/run/cyrus/db/deliver.db";
        hashimapspool = true;
        httpmodules = [
          "carddav"
          "caldav"
        ];
        mboxname_lockpath = "/run/cyrus/lock";
        partition-default = "/var/lib/cyrus/storage";
        popminpoll = 1;
        proc_path = "/run/cyrus/proc";
        ptscache_db_path = "/run/cyrus/db/ptscache.db";
        sasl_auto_transition = true;
        sasl_pwcheck_method = [ "saslauthd" ];
        sievedir = "/var/lib/cyrus/sieve";
        statuscache_db_path = "/run/cyrus/db/statuscache.db";
        syslog_prefix = "cyrus";
        tls_client_ca_dir = "/etc/ssl/certs";
        tls_session_timeout = 1440;
        tls_sessions_db_path = "/run/cyrus/db/tls_sessions.db";
        virtdomains = "on";
      };
      description = "IMAP configuration settings. [imapd.conf(5)](https://www.cyrusimap.org/imap/reference/manpages/configs/imapd.conf.html)";
    };

    user = mkOption {
      type = str;
      default = "cyrus";
      description = "Cyrus IMAP user name.";
    };

    group = mkOption {
      type = str;
      default = "cyrus";
      description = "Cyrus IMAP group name.";
    };

    imapdConfigFile = mkOption {
      type = nullOr path;
      default = null;
      description = "Config file used for the whole cyrus-imap configuration.";
      apply = v: if v != null then v else pkgs.writeText "imapd.conf" imapdConfig;
    };

    cyrusConfigFile = mkOption {
      type = nullOr path;
      default = null;
      description = "Config file used for the whole cyrus-imap configuration.";
      apply = v: if v != null then v else pkgs.writeText "cyrus.conf" cyrusConfig;
    };

    sslCACert = mkOption {
      type = nullOr str;
      default = null;
      description = "File containing one or more Certificate Authority (CA) certificates.";
    };

    sslServerCert = mkOption {
      type = nullOr str;
      default = null;
      description = "File containing the global certificate used for ALL services (imap, pop3, lmtp, sieve)";
    };

    sslServerKey = mkOption {
      type = nullOr str;
      default = null;
      description = "File containing the private key belonging to the global server certificate.";
    };
  };

  config = mkIf cfg.enable {
    users.users.cyrus = optionalAttrs (cfg.user == "cyrus") {
      description = "Cyrus IMAP user";
      isSystemUser = true;
      group = cfg.group;
    };

    users.groups.cyrus = optionalAttrs (cfg.group == "cyrus") { };

    environment.etc."imapd.conf".source = cfg.imapdConfigFile;
    environment.etc."cyrus.conf".source = cfg.cyrusConfigFile;

    systemd.services.cyrus-imap = {
      description = "Cyrus IMAP server";

      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      restartTriggers = [
        cfg.cyrusConfigFile
        cfg.imapdConfigFile
      ];

      startLimitIntervalSec = 60; # 1 min
      environment = {
        CYRUS_VERBOSE = mkIf cfg.debug "1";
        LISTENQUEUE = "${builtins.toString cfg.listenQueue}";
      };
      serviceConfig = {
        User = cfg.user;
        Group = cfg.group;
        Type = "simple";
        ExecStart = "${cyrus-imapdPkg}/libexec/master -l $LISTENQUEUE -C ${cfg.imapdConfigFile} -M ${cfg.cyrusConfigFile} -p /run/cyrus/master.pid -D";
        Restart = "on-failure";
        RestartSec = "1s";
        RuntimeDirectory = [ "cyrus" ];
        StateDirectory = [ "cyrus" ];
        PrivateTmp = "yes";
        AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
      };
      preStart = ''
        mkdir -p '${cfg.imapdSettings.configdirectory}/socket' '${cfg.tmpDBDir}' '/run/cyrus/proc' '/run/cyrus/lock'
      '';
    };
    environment.systemPackages = [ cyrus-imapdPkg ];
  };
}
