
{ config, pkgs, lib, ... }:

with lib;

let
  unstable = import <nixos-unstable> { config = { allowUnfree = true; }; };
in
{
  virtualisation.lxd.enable = true;
  virtualisation.docker.enable = true;
  virtualisation.docker.storageDriver = "zfs";
  virtualisation.docker.autoPrune.enable = true;

  programs.gnupg.agent.enable = true;

  services.clamav.daemon.enable = true;
  services.clamav.updater.enable = true;

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
    package = unstable.plex;
  };
}
