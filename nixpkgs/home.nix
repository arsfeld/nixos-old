{ config, pkgs, ... }:

{
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;


  programs.git = {
    enable = true;
    userName = "Alexandre Rosenfeld";
    userEmail = "arsfeld@gmail.com";
  };

  home.packages = with pkgs; [
    killall
    htop
    unstable.jetbrains.pycharm-community
    sublime3
    sublime-merge
    pam_u2f

    zsh-prezto    
    ncdu # Disk space usage analyzer
    ripgrep # rg, fast grepper
    rtv
    youtube-dl
    gnome3.gnome-tweaks

    unstable.vscode
    #unstable.zoom-us
    unstable.slack
    
    google-chrome
    firefox
  ];
  
  programs = {
    command-not-found.enable = true;
    
    zsh.enable = true;
  };
}
