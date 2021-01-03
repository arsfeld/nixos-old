{ config, pkgs, lib, ... }:

with lib;

{
  time.timeZone = "America/Toronto";

  zramSwap.enable = true;

  users.mutableUsers = true;

  users.extraUsers.root.openssh.authorizedKeys.keys =
    with import ../ssh-keys.nix;
    [ arosenfeld ];

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

  services.openssh.forwardX11 = true;

  environment.systemPackages = with pkgs; [
    gcc
    git
    wget
    vim
    file
    pv
    libva
    lsof
    killall
    sysstat
    hdparm
    sdparm
    htop
    iotop
    lm_sensors
    pciutils
    gptfdisk
    lshw
    hwloc
    mbuffer
    smartmontools
    ntfs3g
    zstd
  ];
}
