{ config, pkgs, lib, ... }:

with lib;

let
  configDir = "/var/nas";
  dataDir = "/mnt/data";
  puid = "8675309";
  pgid = "8675309";
  tz = "America/Toronto";
  networkName = "proxy";
  secrets = import ./secrets.nix;
in {
  systemd.services.init-nas-network = {
    description = "Create the network bridge for nas.";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig.Type = "oneshot";
    script =
      let dockercli = "${config.virtualisation.docker.package}/bin/docker";
      in ''
        # Put a true at the end to prevent getting non-zero return code, which will
        # crash the whole service.
        check=$(${dockercli} network ls | grep "${networkName}" || true)
        if [ -z "$check" ]; then
            ${dockercli} network create ${networkName}
        else
            echo "${networkName} already exists in docker"
        fi
      '';
  };

  virtualisation.oci-containers.containers = {
    "plex" = {
      image = "ghcr.io/linuxserver/plex";
      environment = {
        "PUID" = puid;
        "PGID" = pgid;
        "TZ" = tz;
        "VERSION" = "latest";
        "UMASK_SET" = "022";
      };
      volumes = [ "/var/lib/plex:/config" "${dataDir}:${dataDir}" ];
      extraOptions = [ "--network=host" "--device=/dev/dri:/dev/dri" ];
    };

    "caddy" = {
      image = "lucaslorentz/caddy-docker-proxy:2.3-alpine";
      ports = [ "80:80" "443:443" ];
      volumes = [
        "${configDir}/caddy:/data"
        "/var/run/docker.sock:/var/run/docker.sock"
      ];
      extraOptions = [
        "--link"
        "openvpn"
        "--label"
        "caddy.email=${secrets.email}"
        "--network=${networkName}"
      ];
    };

    "qbittorrent" = {
      image = "ghcr.io/linuxserver/qbittorrent";
      environment = {
        "PUID" = puid;
        "PGID" = pgid;
        "TZ" = tz;
      };
      volumes = [
        "${configDir}/qbittorrent:/config"
        "${dataDir}/media/Downloads:/downloads"
        "${dataDir}/files:/files"
        "${dataDir}/media:/media"
      ];
      extraOptions = [ "--net=container:openvpn" ];
      dependsOn = [ "openvpn" ];
    };

    "openvpn" = {
      image = "dperson/openvpn-client";
      environment = {
        "VPN" =
          "${secrets.openvpn.server};${secrets.openvpn.username};${secrets.openvpn.password}";
        "FIREWALL" = "8080";
      };
      volumes = [ "${configDir}/openvpn:/vpn" ];
      ports = [ "8080:8080" ];
      extraOptions = [
        "--sysctl"
        "net.ipv6.conf.all.disable_ipv6=0"
        "--cap-add=NET_ADMIN"
        "--device"
        "/dev/net/tun"
        "--dns"
        "8.8.8.8"
        "-l"
        "caddy=qbittorrent.${secrets.domain}"
        "-l"
        "caddy.reverse_proxy=192.168.1.10:8080"
      ];
    };

    "transmission" = {
      image = "haugene/transmission-openvpn";
      environment = {
        "PUID" = puid;
        "PGID" = pgid;
        "TZ" = tz;
        "ENABLE_UFW" = "0";
        "LOG_TO_STDOUT" = "1";
        "OPENVPN_PROVIDER" = secrets.openvpn.provider;
        "OPENVPN_CONFIG" = secrets.openvpn.config;
        "OPENVPN_USERNAME" = secrets.openvpn.username;
        "OPENVPN_PASSWORD" = secrets.openvpn.password;
        "TRANSMISSION_DOWNLOAD_DIR" = "/downloads";
        "TRANSMISSION_INCOMPLETE_DIR_ENABLED" = "0";
        "TRANSMISSION_RPC_AUTHENTICATION_REQUIRED" = "true";
        "TRANSMISSION_RPC_USERNAME" = secrets.transmission.username;
        "TRANSMISSION_RPC_PASSWORD" = secrets.transmission.password;
        "TRANSMISSION_ALT_SPEED_TIME_ENABLED" = "true";
        "TRANSMISSION_ALT_SPEED_DOWN" = "500";
        "TRANSMISSION_ALT_SPEED_UP" = "100";
        "TRANSMISSION_SPEED_LIMIT_UP" = "500";
        "TRANSMISSION_SPEED_LIMIT_UP_ENABLED" = "true";
        "TRANSMISSION_RATIO_LIMIT" = "1";
        "TRANSMISSION_RATIO_LIMIT_ENABLED" = "true";
        "TRANSMISSION_PORT_FORWARDING_ENABLED" = "true";
        "TRANSMISSION_PEER_PORT" = "10760";
        "WEBPROXY_ENABLED" = "false";
        "LOCAL_NETWORK" = "192.168.1.0/24";
      };
      ports = [ "9091:9091" ];
      volumes = [
        "${configDir}/transmission:/data"
        "${dataDir}/media/Downloads:/downloads"
        "${dataDir}/files:/files"
        "${dataDir}/media:/media"
      ];
      extraOptions = [
        "-l"
        "caddy=transmission.${secrets.domain}"
        "-l"
        "caddy.reverse_proxy={{upstreams http 9091}}"
        "--sysctl"
        "net.ipv6.conf.all.disable_ipv6=0"
        "--cap-add=NET_ADMIN"
        "--network=${networkName}"
      ];
    };

    "syncthing" = {
      image = "ghcr.io/linuxserver/syncthing";
      environment = {
        "PUID" = puid;
        "PGID" = pgid;
        "TZ" = tz;
        "UMASK_SET" = "022";
      };
      ports = [ "8384:8384" "21027:21027/udp" "22000:22000" ];
      volumes =
        [ "${configDir}/syncthing:/config" "${dataDir}/files/SyncThing:/data" ];
      extraOptions = [
        "-l"
        "caddy=syncthing.${secrets.domain}"
        "-l"
        "caddy.reverse_proxy={{upstreams http 8384}}"
        "--network=${networkName}"
      ];
    };

    "filebrowser" = {
      image = "filebrowser/filebrowser";
      volumes = [
        "${configDir}/filebrowser/filebrowser.db:/database.db"
        "${configDir}/filebrowser/.filebrowser.json:/.filebrowser.json"
        "${dataDir}:/srv"
      ];
      extraOptions = [
        "-l"
        "caddy=filebrowser.${secrets.domain}"
        "-l"
        "caddy.reverse_proxy={{upstreams http 80}}"
        "--network=${networkName}"
      ];
    };

    "jackett" = {
      image = "ghcr.io/linuxserver/jackett";
      environment = {
        "PUID" = puid;
        "PGID" = pgid;
        "TZ" = tz;
      };
      ports = [ "9117:9117" ];
      volumes = [
        "${configDir}/jackett:/config"
        "${dataDir}/files/Torrents:/downloads"
      ];
      extraOptions = [
        "-l"
        "caddy=jackett.${secrets.domain}"
        "-l"
        "caddy.reverse_proxy={{upstreams http 9117}}"
        "--network=${networkName}"
      ];
    };

    "sonarr" = {
      image = "ghcr.io/linuxserver/sonarr";
      environment = {
        "PUID" = puid;
        "PGID" = pgid;
        "TZ" = tz;
      };
      ports = [ "8989:8989" ];
      volumes = [
        "${configDir}/sonarr:/config"
        "${dataDir}/files:/files"
        "${dataDir}/media/Downloads:/downloads"
        "${dataDir}/media:/media"
      ];
      extraOptions = [
        "-l"
        "caddy=sonarr.${secrets.domain}"
        "-l"
        "caddy.reverse_proxy={{upstreams http 8989}}"
        "--network=${networkName}"
      ];
    };

    "radarr" = {
      image = "ghcr.io/linuxserver/radarr";
      environment = {
        "PUID" = puid;
        "PGID" = pgid;
        "TZ" = tz;
      };
      ports = [ "7878:7878" ];
      volumes = [
        "${configDir}/radarr:/config"
        "${dataDir}/media/Downloads:/downloads"
        "${dataDir}/media:/media"
      ];
      extraOptions = [
        "-l"
        "caddy=radarr.${secrets.domain}"
        "-l"
        "caddy.reverse_proxy={{upstreams http 7878}}"
        "--network=${networkName}"
      ];
    };

    "bitwarden" = {
      image = "bitwardenrs/server:latest";
      volumes = [ "${configDir}/bitwarden:/data" ];
      environment = {
        "SIGNUPS_ALLOWED" = "false";
        "ADMIN_TOKEN" = secrets.bitwarden.adminToken;
      };
      extraOptions = [
        "-l"
        "caddy=bitwarden.${secrets.domain}"
        "-l"
        "caddy.reverse_proxy={{upstreams http 80}}"
        "--network=${networkName}"
      ];
    };

    "watchtower" = {
      image = "containrrr/watchtower";
      environment = {
        "TZ" = tz;
        "WATCHTOWER_CLEANUP" = "true";
        "WATCHTOWER_SCHEDULE" = "0 1 * * *";
      };
      volumes = [ "/var/run/docker.sock:/var/run/docker.sock" ];
    };

    "cloudflare-ddns" = {
      image = "oznu/cloudflare-ddns:latest";
      environment = {
        "EMAIL" = secrets.email;
        "API_KEY" = secrets.cloudflareToken;
        "ZONE" = secrets.domain;
      };
    };

    # "pihole" = {
    #   image = "pihole/pihole:latest";
    #   environment = {
    #     "TZ" = tz;
    #     "VIRTUAL_HOST" = "pihole.${secrets.domain}";
    #     "WEBPASSWORD" = secrets.pihole.password;
    #   };
    #   ports = [
    #     "${secrets.pihole.ipAddress}:53:53/tcp"
    #     "${secrets.pihole.ipAddress}:53:53/udp"
    #     #"192.168.1.10:67:67/udp"
    #     #"80:80/tcp"
    #     #"443:443/tcp"
    #   ];
    #   volumes = [
    #     "${configDir}/pihole/etc:/etc/pihole"
    #     "${configDir}/pihole/dnsmasq:/etc/dnsmasq.d"
    #   ];
    #   extraOptions = [
    #     "-l"
    #     "caddy=pihole.${secrets.domain}"
    #     "-l"
    #     "caddy.reverse_proxy={{upstreams http 80}}"
    #     "--dns"
    #     "1.1.1.1"
    #     "--dns"
    #     "127.0.0.1"
    #     "--cap-add=NET_ADMIN"
    #     "--network=${networkName}"
    #   ];
    # };
  };
}
