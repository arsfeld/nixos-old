
{ config, pkgs, lib, ... }:

with lib;

{
  virtualisation.lxd.enable = true;
  virtualisation.docker.enable = true;

  services.openssh.enable = true;
  
  services.netdata.enable = true;

  services.plex = {
    enable = true;
    openFirewall = true;
    user = "media";
    group = "media";
  };


}