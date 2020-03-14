
{ config, pkgs, lib, ... }:

with lib;

{
  virtualisation.lxd.enable = true;
  virtualisation.docker.enable = true;
  virtualisation.docker.storageDriver = "zfs";
  virtualisation.docker.autoPrune.enable = true;

  services.openssh.enable = true;
  
  services.netdata.enable = true;

  services.avahi.enable = true;
  services.avahi.publish.enable = true;
  services.avahi.publish.userServices = true;
  services.avahi.publish.workstation = true;

  services.plex = {
    enable = true;
    openFirewall = true;
    user = "media";
    group = "media";
  };

  systemd.services.nas = {
    description = "Docker based NAS applications";
    wantedBy = [ "multi-user.target" ];
    after = [ "docker.service" "docker.socket" "zfs-mount.service" ];
    requires = [ "docker.service" "docker.socket" "zfs-mount.service" ];
    script = "${pkgs.docker-compose}/bin/docker-compose up";
    serviceConfig = {
      ExecStartPre = [
      	"-${pkgs.docker-compose}/bin/docker-compose down -v"
        "-${pkgs.docker-compose}/bin/docker-compose rm -fv"
        "-${pkgs.docker} network create proxy"
      ];
      ExecStop = "${pkgs.docker-compose}/bin/docker-compose down -v";
      TimeoutStartSec = 0;
      TimeoutStopSec = 120;
      Restart = "always";
      WorkingDirectory = "/etc/nas";
    };
  };

# sudo docker run -it --name bit --net=container:vpn -d dperson/transmission
# sudo docker run -it --name web -p 80:80 -p 443:443 --link vpn:bit \
#             -d dperson/nginx -w "http://bit:9091/transmission;/transmission"

  # docker-containers.transmission = {
  #   image = "dperson/transmission";
  # };


  containers.pihole =
  { 
    autoStart = true;
    privateNetwork = true;
    config =
      { config, pkgs, ... }:
      { 
        docker-containers.pi-hole = {
          image = "pihole/pihole:latest";
          ports = [
              "53:53/tcp"
              "53:53/udp"
              "67:67/udp"
              "80:80/tcp"
              "443:443/tcp"
          ];

          environment = {
            "TZ" = "America/Toronto";
          };

          volumes = [
            "/var/pi-hole/etc-pihole:/etc/pihole/"
            "/var/pi-hole/etc-dnsmasq.d:/etc/dnsmasq.d/"
          ];

          extraDockerOptions = [
            "--dns=127.0.0.1"
            "--dns=1.1.1.1"
          ];
        };
      };
  };
}
