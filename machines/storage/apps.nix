
{ config, pkgs, lib, ... }:

with lib;

{
  virtualisation.lxd.enable = true;
  virtualisation.docker.enable = true;

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
    #preStop = "${pkgs.docker}/bin/docker stop prometheus";
    #reload = "${pkgs.docker}/bin/docker restart prometheus";
    serviceConfig = {
      ExecStartPre = [
      	"-${pkgs.docker-compose}/bin/docker-compose down -v"
        "-${pkgs.docker-compose}/bin/docker-compose rm -fv"
      ];
      ExecStop = "${pkgs.docker-compose}/bin/docker-compose down -v";
      TimeoutStartSec = 0;
      TimeoutStopSec = 120;
      Restart = "always";
      WorkingDirectory = "/etc/nas";
    };
  };
}
