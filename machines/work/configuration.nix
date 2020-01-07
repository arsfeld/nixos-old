# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ 
      <nixos-hardware/dell/xps/13-7390>
      ../../modules/common.nix
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;
  #boot.kernelParams = [ "nomodeset" ];
  services.fwupd.enable = true;

  boot.zfs.requestEncryptionCredentials = true;

  networking.hostName = "Alex-Rosenfeld-XPS-13"; # Define your hostname.
  networking.hostId = "6fa2a99e";
  
  zramSwap.algorithm = "zstd";

  services.zfs = {
    autoSnapshot.enable = true;
    autoScrub.enable = true;
    trim.enable = true;
  };

  services.xserver = {
    enable = true;

    libinput.enable = true;

    displayManager = {
      #defaultSession = "gnome-xorg";
      gdm = {
        enable = true;
        wayland = true;
      };
    };

    desktopManager = {
      gnome3 = {
        enable = true;
      };
    };
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.arosenfeld = {
    isNormalUser = true;
    extraGroups = [ "wheel" "docker" "lxd" ]; # Enable ‘sudo’ for the user.
  };

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "20.03"; # Did you read the comment?

}

