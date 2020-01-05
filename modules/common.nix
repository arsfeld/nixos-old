
{ config, pkgs, lib, ... }:

with lib;

{
  time.timeZone = "America/Toronto";

  zramSwap.enable = true;

  users.mutableUsers = true;

  users.extraUsers.root.openssh.authorizedKeys.keys =
     with import ../ssh-keys.nix; [ arosenfeld ];

  #nix.useSandbox = true;
  #nix.buildCores = 0;
  #nix.nixPath = [ "nixpkgs=channel:nixos-19.09" ];
  #nix.extraOptions =
  #  ''
  #    experimental-features = nix-command flakes ca-references
  #  '';

  nixpkgs.config.allowUnfree = true;

  hardware.enableAllFirmware = true;
  #hardware.cpu.amd.updateMicrocode = true;
  hardware.cpu.intel.updateMicrocode = true;

  environment.systemPackages = with pkgs; [
    git
    wget 
    vim
    file 
    pv 
    lsof 
    killall 
    sysstat 
    hdparm 
    sdparm
    htop 
    iotop 
    lm_sensors 
    hwloc
    smartmontools
    ntfs3g 
  ];
}