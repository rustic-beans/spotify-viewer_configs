# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

let
  autostart = ''
    #!${pkgs.bash}/bin/bash

    firefox --kiosk https://whatsplaying.analogio.dk/ &
  '';

  inherit (pkgs) writeScript;
in
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Copenhagen";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_DK.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "da_DK.UTF-8";
    LC_IDENTIFICATION = "da_DK.UTF-8";
    LC_MEASUREMENT = "da_DK.UTF-8";
    LC_MONETARY = "da_DK.UTF-8";
    LC_NAME = "da_DK.UTF-8";
    LC_NUMERIC = "da_DK.UTF-8";
    LC_PAPER = "da_DK.UTF-8";
    LC_TELEPHONE = "da_DK.UTF-8";
    LC_TIME = "da_DK.UTF-8";
  };


  # Enable the X11 windowing system.
  services = {
    displayManager = {
      defaultSession = "none+openbox";
      autoLogin = {
        enable = true;
        user = "analog";
      };
    };
    xserver = {
      enable = true;
      # Configure keymap in X11
      xkb = {
        layout = "us";
        variant = "";
      };
      windowManager.openbox.enable = true;
      displayManager = {
        lightdm.enable = true;
      };
    };
  };

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.analog = {
    isNormalUser = true;
    description = "Cafe Analog";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
    #  thunderbird
    ];
    openssh.authorizedKeys.keys = [
    	"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINjXQKadlTBbtNCEXUiV6ug7G4rLy1KboJQqMiaoD7yV goose"
	"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBA6klmMF+uwhYvapBkeuRSFyhOpCH0V7JfSE4nnZjBE slugboi"
    ];
  };

  # Workaround for GNOME autologin: https://github.com/NixOS/nixpkgs/issues/103746#issuecomment-945091229
  systemd.services."getty@tty1".enable = true;
  systemd.services."autovt@tty1".enable = true;
  systemd.services."getty@tty2".enable = true;
  services.logind.extraConfig = ''
    NAutoVTs=6
    ReserveVT=1
  '';
  
  # Disable sleep timeout
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  powerManagement.enable = false;

  systemd.services."display-manager".after = [
    "network-online.target"
    "systemd-resolved.service"
  ];

  # Install firefox.
  programs = {
        firefox.enable = true;
	neovim.enable = true;
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Overlay to set custom autostart script for openbox
  nixpkgs.overlays = with pkgs; [
    (_self: super: {
      openbox = super.openbox.overrideAttrs (_oldAttrs: rec {
        postFixup = ''
          ln -sf /etc/openbox/autostart $out/etc/xdg/openbox/autostart
        '';
      });
    })
  ];

  # By defining the script source outside of the overlay, we don't have to
  # rebuild the package every time we change the startup script.
  environment.etc."openbox/autostart".source = writeScript "autostart" autostart;

   environment.extraInit = ''
    xset s off -dpms
    xset s off     # Disable screensaver
    xset s noblank # Don't blank video device
   '';

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?

}
