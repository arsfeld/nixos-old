{ config, pkgs, lib, ... }:

with lib;

{
  virtualisation.lxd.enable = true;
  virtualisation.docker = {
    enable = true;
    storageDriver = "zfs";
    autoPrune.enable = true;
    extraOptions = "--registry-mirror=https://mirror.gcr.io";
  };

  programs.gnupg.agent.enable = true;

  services.openssh.enable = true;

  services.netdata.enable = true;

  services.avahi = {
    enable = true;
    publish = {
      enable = true;
      userServices = true;
      workstation = true;
    };
  };
}
