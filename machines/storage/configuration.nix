{ config, pkgs, ... }:

{
  imports =
    [ 
      ../../modules/common.nix
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./zfs.nix
      ./apps.nix
      ./sharing.nix
      ./users.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "storage"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.eno1.useDHCP = true;
  #networking.interfaces.wlp4s0.useDHCP = true;

  networking.hostId = "d5325dbe";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    firefox
  ];

  programs.zsh.enable = true;

  # Enable Oh-my-zsh
  programs.zsh.ohMyZsh = {
    enable = true;
    plugins = [ "git" "sudo" "docker" "kubectl" ];
  };

  programs.command-not-found.enable = true;

  networking.firewall.enable = false;

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    libinput.enable = true;
    
    displayManager.gdm.enable = true;
    desktopManager.gnome3.enable = true;
  };
  

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "19.09"; # Did you read the comment?

}

