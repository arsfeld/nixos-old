# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let
  hardware = import <nixos-hardware> {};
  unstable = import <nixos-unstable> {};
in {
  imports = 
    [ # Include the results of the hardware scan. 
      <nixos-hardware/common/cpu/intel>
      <nixos-hardware/common/pc/laptop>
      <nixos-hardware/common/pc/laptop/ssd>
      ./hardware-configuration.nix
    ];

  nixpkgs.config = {
    # Allow proprietary packages
    allowUnfree = true;
  
    # Create an alias for the unstable channel
    packageOverrides = pkgs: {
      unstable = import <nixos-unstable> {
        # pass the nixpkgs config to the unstable alias
        # to ensure `allowUnfree = true;` is propagated:
        config = config.nixpkgs.config;
      };
    };  
  };

  services.udev.extraRules = ''
    # set deadline scheduler for non-rotating disks
    # according to https://wiki.debian.org/SSDOptimization, deadline is preferred over noop
    ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="bfq"
    # https://support.google.com/titansecuritykey/answer/9148044?hl=en
    ACTION=="add|change", KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="18d1", ATTRS{idProduct}=="5026", TAG+="uaccess"
  '';

  security.pam.u2f = {
    enable = true;
    control = "sufficient";
    cue = true;
  }; 
  hardware.u2f.enable = true;

  # let's have a bootsplash!
  boot.plymouth.enable = true;

  boot.kernelParams = [ "i915.fastboot=1" ];
  #boot.kernelPackages = pkgs.linuxPackages;

  boot.supportedFilesystems = [ "f2fs" ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  nix.autoOptimiseStore = true;

  #boot.extraModulePackages = [ config.boot.kernelPackages.exfat-nofuse ];

  zramSwap = {
    enable = true;
    algorithm = "zstd";
  };

  networking.hostName = "nixos"; # Define your hostname.

  networking.useDHCP = false;

  # Set your time zone.
  time.timeZone = "America/Toronto";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    wget vim gnupg git usbutils
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = { enable = true; enableSSHSupport = true; };

  # List services that you want to enable:
  services.flatpak.enable = true;
  xdg.portal.enable = true;
  services.fwupd.enable = true;

  virtualisation.lxd.enable = true;
  virtualisation.docker.enable = true;

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;
  services.resolved.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  services.xserver = {
    enable = true;

    # Chromebook touchpad
    cmt = {
      enable = false;
      models = "lulu";
    };
    libinput.enable = true;

    displayManager = {
      gdm = {
        enable = false;
        wayland = false;
      };
      lightdm = {
        enable = true;
        greeters.gtk.enable = false;
        greeters.enso.enable = true;
      };
    };

    desktopManager = {
      #default = "gnome3";
      xterm.enable = false;
      #xfce4-14.enable = true;
      pantheon.enable = true;
      gnome3 = {
        enable = false;
        #flashback.enableMetacity = true;
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
  system.stateVersion = "19.09"; # Did you read the comment?

}

