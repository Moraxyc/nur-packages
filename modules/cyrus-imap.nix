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

  cyrusOptions =
    { ... }:
    {
      options = {
        cmd = mkOption {
          type = listOf str;
          description = "The command (with options) to spawn as a child process. This string argument is required.";
          example = literalExpression ''
            ["imapd" "-s"]
          '';
        };
        babysit = mkOption {
          type = nullOr int;
          default = null;
          description = "Integer value - if non-zero, will make sure at least one process is pre-forked, and will set the maxforkrate to 10 if it's zero.";
          example = 0;
        };
        listen = mkOption {
          type = nullOr str;
          default = null;
          description = ''
            The UNIX or internet socket to listen on. This string field is required and takes one of the following forms:
            path
            [ host : ] port
            where path is the explicit path to a UNIX socket, host is either the hostname or bracket-enclosed IP address of a network interface, and port is either a port number or service name (as listed in /etc/services).
            If host is missing, 0.0.0.0 (all interfaces) is assumed. Use localhost or 127.0.0.1 to restrict access, i.e. when a proxy on the same host is front-ending Cyrus.
            Note that on most systems UNIX socket paths are limited to around 100 characters. See your system documentation for specifics.
          '';
          example = "/run/cyrus/lmtp";
        };
        proto = mkOption {
          type = nullOr (enum [
            "tcp"
            "tcp4"
            "tcp6"
            "udp"
            "udp4"
            "udp6"
          ]);
          default = null;
          description = ''
            The protocol used for this service (tcp, tcp4, tcp6, udp, udp4, udp6). This string argument is optional.
            tcp4, udp4: These arguments are used to bind the service to IPv4 only.
            tcp6, udp6: These arguments are used to bind the service to IPv6 only, if the operating system supports this.
            tcp, udp: These arguments are used to bind to both IPv4 and IPv6 if possible.
          '';
          example = "tcp";
        };
        prefork = mkOption {
          type = nullOr int;
          default = null;
          description = ''
            The number of instances of this service to always have running and waiting for a connection (for faster initial response time).
            This integer value is optional. Note that if you are listening on multiple network types (i.e. ipv4 and ipv6) then one process will be forked for each address, causing twice as many processes as you might expect.
          '';
          example = 0;
        };
        maxchild = mkOption {
          type = nullOr int;
          default = null;
          description = ''
            The maximum number of instances of this service to spawn. A value of -1 means unlimited. This integer value is optional.
          '';
          example = -1;
        };
        maxfds = mkOption {
          type = nullOr int;
          default = null;
          description = ''
            The maximum number of file descriptors to which to limit this process. This integer value is optional.
          '';
          example = 256;
        };
        maxforkrate = mkOption {
          type = nullOr int;
          default = null;
          description = ''
            Maximum number of processes to fork per second - the master will insert sleeps to ensure it doesn't fork faster than this on average.
          '';
          example = 0;
        };
        period = mkOption {
          type = nullOr int;
          default = null;
          description = ''
            The interval (in minutes) at which to run the command. This integer value is optional, but SHOULD be a positive integer > 10.
          '';
          example = 0;
        };
        at = mkOption {
          type = nullOr int;
          default = null;
          description = ''
            The time (24-hour format) at which to run the command each day. If set to a valid time (0000-2359), period is automatically set to 1440. This string argument is optional.
          '';
          example = 0;
        };
        wait = mkOption {
          type = nullOr str;
          default = null;
          description = ''
            Switch: whether or not master(8) should wait for this daemon to successfully start before continuing to load.
            If wait=n (the default), the daemon will be started asynchronously along with the service processes. The daemon process will not have file descriptor 3 open, and does not need to indicate its readiness.
            If wait=y, the daemon MUST write "ok\r\n" to file descriptor 3 to indicate its readiness; if it does not do this, and master has been told to wait, master will continue to wait.... If it writes anything else to this descriptor, or closes it before writing "ok\r\n", master will exit with an error.
            Daemons with wait=y will be started sequentially in the order they are listed in cyrus.conf, waiting for each to report readiness before the next is started.
            Service processes, and wait=n daemons, are not started until after the wait=y daemons are all started and ready.
            At shutdown, wait=y daemons will be terminated sequentially in the reverse order they were started, commencing after all other services and wait=n daemons have finished.
            If a daemon that was started with wait=y exits unexpectedly, such that master restarts it, master will restart it asynchronously, without waiting for it to report its readiness. In this case, file descriptor 3 will not be open and the daemon should not try to write to it.
            If master is told to reread its config with a SIGHUP, this signal will be passed on to wait=y daemons like any other service. If the daemon exits in response to the signal, master will restart it asynchronously, without waiting for it to report its readiness. In this case too, file descriptor 3 will not be open and the daemon should not try to write to it.
          '';
          example = "0";
        };
      };
    };
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
    cyrusSettings = {
      START = mkOption {
        default = {
          recover = {
            cmd = [
              "ctl_cyrusdb"
              "-r"
            ];
          };
        };
        type = attrsOf (submodule cyrusOptions);
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
        type = attrsOf (submodule cyrusOptions);
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
        type = attrsOf (submodule cyrusOptions);
        description = ''
          This section lists processes that should be run at specific intervals, similar to cron jobs. This section is typically used to perform scheduled cleanup/maintenance.
        '';
      };
      DAEMON = mkOption {
        default = { };
        type = attrsOf (submodule cyrusOptions);
        description = ''
          This section lists long running daemons to start before any SERVICES are spawned. master(8) will ensure that these processes are running, restarting any process which dies or forks. All listed processes will be shutdown when master(8) is exiting.
        '';
      };
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
          admins = mkOption {
            type = listOf str;
            default = [ "cyrus" ];
            description = ''
              The list or string of userids with administrative rights.
              Note that accounts used by users should not be administrators. Administrative accounts should not receive mail. That is, if user "jbRo" is a user reading mail, he should not also be in the admins line. Some problems may occur otherwise, most notably the ability of administrators to create top-level mailboxes visible to users, but not writable by users.
            '';
          };
          configdirectory = mkOption {
            type = path;
            default = "/var/lib/cyrus";
            description = ''
              The pathname of the IMAP configuration directory. This field is required.
            '';
          };
          proc_path = mkOption {
            type = path;
            default = "/run/cyrus/proc";
            description = ''
              Path to proc directory. Default is NULL - must be an absolute path if specified.
            '';
          };
          tls_sessions_db_path = mkOption {
            type = path;
            default = "/run/cyrus/db/tls_sessions.db";
            description = ''
              The absolute path to the TLS sessions db file.
            '';
          };
          statuscache_db_path = mkOption {
            type = path;
            default = "/run/cyrus/db/statuscache.db";
            description = ''
              The absolute path to the statuscache db file.
            '';
          };
          ptscache_db_path = mkOption {
            type = path;
            default = "/run/cyrus/db/ptscache.db";
            description = ''
              The absolute path to the ptscache db file.
            '';
          };
          duplicate_db_path = mkOption {
            type = path;
            default = "/run/cyrus/db/deliver.db";
            description = ''
              The absolute path to the duplicate db file.
            '';
          };
          mboxname_lockpath = mkOption {
            type = path;
            default = "/run/cyrus/lock";
            description = ''
              Path to mailbox name lock files
            '';
          };
          tls_session_timeout = mkOption {
            type = ints.between 0 1440;
            default = 1440;
            description = ''
              The length of time (in minutes) that a TLS session will be cached for later reuse.
              The maximum value is 1440 (24 hours), the default.
              A value of 0 will disable session caching.
            '';
          };
          sasl_auto_transition = mkOption {
            type = bool;
            default = true;
            description = ''
              If enabled, the SASL library will automatically create authentication secrets when given a plaintext password. See the SASL documentation.
            '';
          };
          allowplaintext = mkOption {
            type = bool;
            default = true;
            description = ''
              Allow plaintext logins by default (SASL PLAIN)
            '';
          };
          sievedir = mkOption {
            type = path;
            default = "/var/lib/cyrus/sieve";
            description = ''
              If sieveusehomedir is false, this directory is searched for Sieve scripts.
            '';
          };
          partition-default = mkOption {
            type = str;
            default = "/var/lib/cyrus/storage";
            description = ''
              The pathname of the partition **default**.
            '';
          };
          defaultpartition = mkOption {
            type = str;
            default = "default";
            description = ''
              The partition name used by default for new mailboxes. If not specified, the partition with the most free space will be used for new mailboxes.
              Note that the partition specified by this option must also be specified as partition-name, where you substitute 'name' for the alphanumeric string you set defaultpartition to.
            '';
          };
          popminpoll = mkOption {
            type = int;
            default = 1;
            description = ''
              Minimum time between POP mail fetches in minutes   The default domain for virtual domain support
            '';
          };
          defaultdomain = mkOption {
            type = str;
            default = "localhost";
            description = ''
              The default domain for virtual domain support
            '';
          };
          virtdomains = mkOption {
            type = enum [
              "off"
              "userid"
              "on"
            ];
            default = "on";
            description = ''
              off: Cyrus does not know or care about domains. Only the local part of email addresses is ever considered. This is not recommended for any deployment.

              userid: The user's domain is determined by splitting a fully qualified userid at the last '@' or '%' symbol. If the userid is unqualified, the defaultdomain will be used. This is the recommended configuration for all deployments. If you wish to provide calendaring services you must use this configuration.

              on: Fully qualified userids are respected, as per "userid". Unqualified userids will have their domain determined by doing a reverse lookup on the IP address of the incoming network interface, or if no record is found, the defaultdomain will be used.

              Allowed values: off, userid, on
            '';
          };
          hashimapspool = mkOption {
            type = bool;
            default = true;
            description = ''
              If enabled, the partitions will also be hashed, in addition to the hashing done on configuration directories.
              This is recommended if one partition has a very bushy mailbox tree.
            '';
          };
          httpmodules = mkOption {
            type = listOf str;
            example = [
              "caldav"
              "carddav"
              "domainkey"
              "ischedule, rss"
            ];
            default = [ "caldav" ];
            description = ''
              List of HTTP modules that will be enabled in httpd(8).
              Allowed values: caldav carddav domainkey ischedule rss
            '';
          };
          sasl_pwcheck_method = mkOption {
            type = listOf str;
            default = [ "pwcheck" ];
            example = [
              "saslauthd"
              "auxprop"
              "pwcheck"
            ];
            description = ''
              The mechanism(s) used by the server to verify plaintext passwords.
              Possible values are "saslauthd", "auxprop", "pwcheck" and "alwaystrue".  They are tried in order, you can specify more than one.
            '';
          };
        };
      };
      default = { };
      description = "IMAP configuration settings. imapd.conf(5)";
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
    services.cyrus-imap = {
      imapdSettings = {
        syslog_prefix = "cyrus";
        lmtpsocket = "/run/cyrus/lmtp";
        idlesocket = "/run/cyrus/idle";
        notifysocket = "/run/cyrus/notify";
        tls_server_cert = mkIf (cfg.sslServerCert != null) cfg.sslServerCert;
        tls_server_key = mkIf (cfg.sslServerKey != null) cfg.sslServerKey;
        tls_client_ca_file = mkIf (cfg.sslCACert != null) cfg.sslCACert;
        tls_client_ca_dir = "/etc/ssl/certs";
      };
    };

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
