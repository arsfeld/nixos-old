
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
in
{
    systemd.services.init-nas-network = {
        description = "Create the network bridge for nas.";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
  
        serviceConfig.Type = "oneshot";
        script = let dockercli = "${config.virtualisation.docker.package}/bin/docker";
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

    docker-containers."caddy" = {
        image = "lucaslorentz/caddy-docker-proxy:2.1-alpine";
        ports = [
            "80:80"
            "443:443"
        ];
        volumes = [
            "${configDir}/caddy:/data"
            "/var/run/docker.sock:/var/run/docker.sock"
        ];
        extraDockerOptions = [ 
            "--label" "caddy.email=${secrets.email}"
            "--network=${networkName}" 
        ];
    };

    docker-containers."qbittorrent" = {
        image = "linuxserver/qbittorrent";
        environment = {
            "PUID" = puid;
            "PGID" = pgid;
            "TZ" = tz;
        };
        volumes = [ 
            "${configDir}/qbittorrent:/config"
            "${dataDir}/files/Downloads:/downloads"
            "${dataDir}/files:/files" 
            "${dataDir}/media:/media" 
        ];
        extraDockerOptions = [
            "--net=container:openvpn"
        ];
        dependsOn = ["openvpn"];
    };

    docker-containers."qbittorrent-web" = {
        image = "dperson/nginx";
        cmd = ["-w" "http://qbittorrent:8080/;/"];
        extraDockerOptions = [ 
            "--link" "openvpn:qbittorrent"
            "-l" "caddy=qbittorrent.${secrets.domain}"
            "-l" "caddy.reverse_proxy={{upstreams http 80}}"
            "--network=${networkName}" 
        ];
        dependsOn = ["qbittorrent"];
    };

    docker-containers."openvpn" = {
        image = "dperson/openvpn-client";
        environment = {
            "VPN" = "${secrets.openvpn.server};${secrets.openvpn.username};${secrets.openvpn.password}";
        };
        volumes = [
            "${configDir}/openvpn:/vpn"
        ];
        extraDockerOptions = [
            "--sysctl" "net.ipv6.conf.all.disable_ipv6=0"
            "--cap-add=NET_ADMIN" "--device" "/dev/net/tun"
        ];
    };

    docker-containers."transmission" = {
        image = "haugene/transmission-openvpn";
        environment = {
            "PUID" = puid;
            "PGID" = pgid;
            "TZ" = tz;
            "ENABLE_UFW" = "0";
            "CREATE_TUN_DEVICE" = "true";
            "OPENVPN_PROVIDER" = secrets.openvpn.provider;
            "OPENVPN_CONFIG" = secrets.openvpn.config;
            "OPENVPN_USERNAME" = secrets.openvpn.username;
            "OPENVPN_PASSWORD" = secrets.openvpn.password;
            "TRANSMISSION_DOWNLOAD_DIR" = "/media/Downloads";
            "TRANSMISSION_INCOMPLETE_DIR_ENABLED" = "0";
            "TRANSMISSION_RPC_AUTHENTICATION_REQUIRED" = "true";
            "TRANSMISSION_RPC_USERNAME" = secrets.transmission.username;
            "TRANSMISSION_RPC_PASSWORD" = secrets.transmission.password;
            "TRANSMISSION_SPEED_LIMIT_UP" = "500";
            "TRANSMISSION_SPEED_LIMIT_UP_ENABLED" = "1";
            "TRANSMISSION_RATIO_LIMIT" = "1";
            "TRANSMISSION_RATIO_LIMIT_ENABLED" = "1";
            "TRANSMISSION_PORT_FORWARDING_ENABLED" = "1";
            "TRANSMISSION_PEER_PORT" = "10760";
            "WEBPROXY_ENABLED" = "false";
            "LOCAL_NETWORK" = "192.168.1.0/24";
        };
        ports = [
            "9091:9091"
        ];
        volumes = [ 
            "${configDir}/transmission:/data"
            "${dataDir}/files/Downloads:/downloads"
            "${dataDir}/files:/files" 
            "${dataDir}/media:/media" 
        ];
        extraDockerOptions = [ 
            "-l" "caddy=transmission.${secrets.domain}"
            "-l" "caddy.reverse_proxy={{upstreams http 9091}}"
            "--sysctl" "net.ipv6.conf.all.disable_ipv6=0" 
            "--cap-add=NET_ADMIN" 
            "--network=${networkName}"
        ];
    };

    docker-containers."transmission-rss" = {
        image = "nning2/transmission-rss";
        volumes = [
            "${configDir}/transmission-rss/transmission-rss.conf:/etc/transmission-rss.conf"
            "${configDir}/transmission-rss/seen:/seen"
        ];
    };

    docker-containers."syncthing" = {
        image = "linuxserver/syncthing";
        environment = {
            "PUID" = puid;
            "PGID" = pgid;
            "TZ" = tz;
            "UMASK_SET" = "022";
        };
        ports = [
            "8384:8384"
            "21027:21027/udp"
            "22000:22000"
        ];
        volumes = [ 
            "${configDir}/syncthing:/config"
            "${dataDir}/files/SyncThing:/data"
        ];
        extraDockerOptions = [ 
            "-l" "caddy=syncthing.${secrets.domain}"
            "-l" "caddy.reverse_proxy={{upstreams http 8384}}"
            "--network=${networkName}" 
        ];
    };

    docker-containers."filebrowser" = {
        image = "filebrowser/filebrowser";
        volumes = [
            "${configDir}/filebrowser/filebrowser.db:/database.db"
            "${configDir}/filebrowser/.filebrowser.json:/.filebrowser.json"
            "${dataDir}:/srv"
        ];
        extraDockerOptions = [
            "-l" "caddy=filebrowser.${secrets.domain}"
            "-l" "caddy.reverse_proxy={{upstreams http 80}}"
            "--network=${networkName}"
        ];
    };

    docker-containers."jackett" = {
        image = "linuxserver/jackett";
        environment = {
            "PUID" = puid;
            "PGID" = pgid;
            "TZ" = tz;
        };
        ports = [
            "9117:9117"
        ];
        volumes = [ 
            "${configDir}/jackett:/config"
            "${dataDir}/files/Torrents:/downloads"
        ];
        extraDockerOptions = [
            "-l" "caddy=jackett.${secrets.domain}"
            "-l" "caddy.reverse_proxy={{upstreams http 9117}}" 
            "--network=${networkName}" 
        ];
    };

    docker-containers."sonarr" = {
        image = "linuxserver/sonarr";
        environment = {
            "PUID" = puid;
            "PGID" = pgid;
            "TZ" = tz;
        };
        ports = [
            "8989:8989"
        ];
        volumes = [ 
            "${configDir}/sonarr:/config"
            "${dataDir}/files:/files"
            "${dataDir}/files/Downloads:/downloads"
            "${dataDir}/media:/media"
        ];
        extraDockerOptions = [ 
            "-l" "caddy=sonarr.${secrets.domain}"
            "-l" "caddy.reverse_proxy={{upstreams http 8989}}"
            "--network=${networkName}" 
        ];
    };

    docker-containers."radarr" = {
        image = "linuxserver/radarr";
        environment = {
            "PUID" = puid;
            "PGID" = pgid;
            "TZ" = tz;
        };
        ports = [
            "7878:7878"
        ];
        volumes = [
            "${configDir}/radarr:/config"
            "${dataDir}/media/Downloads:/downloads"
            "${dataDir}/media:/media"
        ];
        extraDockerOptions = [
            "-l" "caddy=radarr.${secrets.domain}"
            "-l" "caddy.reverse_proxy={{upstreams http 7878}}"
            "--network=${networkName}"
        ];
    };

    docker-containers."bitwarden" = {
        image = "bitwardenrs/server:latest";
        volumes = [
            "${configDir}/bitwarden:/data"
        ];
        environment = {
            "SIGNUPS_ALLOWED" = "false";
        };
        extraDockerOptions = [ 
            "-l" "caddy=bitwarden.${secrets.domain}"
            "-l" "caddy.reverse_proxy={{upstreams http 80}}"
            "--network=${networkName}" 
        ];
    };

    docker-containers."ouroboros" = {
        image = "pyouroboros/ouroboros";
        environment = {
            "TZ" = tz;
            "CLEANUP" = "true";
            "SELF_UPDATE" = "true";
        };
        volumes = [
            "/var/run/docker.sock:/var/run/docker.sock"
        ];
    };

    docker-containers."cloudflare-ddns" = {
        image = "oznu/cloudflare-ddns:latest";
        environment = {
            "EMAIL" = secrets.email;
            "API_KEY" = secrets.cloudflareToken;
            "ZONE" = secrets.domain;
        };
    };


    docker-containers."pihole" = {
        image = "pihole/pihole:latest";
        environment = {
            "TZ" = tz;
            "VIRTUAL_HOST" = "pihole.${secrets.domain}";
            "WEBPASSWORD" = secrets.pihole.password;
        };
        ports = [
            "${secrets.pihole.ipAddress}:53:53/tcp"
            "${secrets.pihole.ipAddress}:53:53/udp"
            #"192.168.1.10:67:67/udp"
            #"80:80/tcp"
            #"443:443/tcp"
        ];
        volumes = [ 
            "${configDir}/pihole/etc:/etc/pihole"
            "${configDir}/pihole/dnsmasq:/etc/dnsmasq.d"
        ];
        extraDockerOptions = [ 
            "-l" "caddy=pihole.${secrets.domain}"
            "-l" "caddy.reverse_proxy={{upstreams http 80}}"
            "--dns" "1.1.1.1"
            "--dns" "127.0.0.1" 
            "--cap-add=NET_ADMIN" 
            "--network=${networkName}"
        ];
    };
}
