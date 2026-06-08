# Reusable NixOS VM module factory.
#
# Usage in flake.nix:
#   nixosConfigurations.dev-vm = nixpkgs.lib.nixosSystem {
#     system = "x86_64-linux";
#     specialArgs = { inherit self; };
#     modules = [
#       (import ./_lib/vm-module.nix {
#         hostname = "dev-vm";
#         extraPackages = pkgs: with pkgs; [ rustc cargo ... ];
#         extraOverlays = [ (import rust-overlay) ];
#       })
#     ];
#   };
#
# `just vm` builds and runs the VM. The project source is mounted at /home/dev/project.
{ hostname ? "dev-vm"
, extraPackages ? (_pkgs: [ ])
, extraOverlays ? [ ]
, memorySize ? 8192
, cores ? 4
, diskSize ? 20480
, sshPortForward ? 2222
}:

{ config, pkgs, lib, self ? null, ... }:

let
  sharedTools = import ./shared-tools.nix { inherit pkgs; };
in
{
  system.stateVersion = "26.05";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  networking.hostName = hostname;
  networking.networkmanager.enable = true;
  networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];
  networking.firewall.allowedTCPPorts = [ 22 ];

  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "no";

  users.users.dev = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    initialPassword = "dev";
    home = "/home/dev";
  };

  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = extraOverlays;

  environment.systemPackages =
    (with pkgs; [
      git vim htop curl wget jq gh
      nodejs_26
      just
      gcc gnumake pkg-config openssl
    ])
    ++ sharedTools.aiCodingTools
    ++ sharedTools.formalVerificationTools
    ++ (extraPackages pkgs);

  # Required for dynamically-linked binaries from npm (agent-browser, etc.).
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib zlib openssl curl libGL
    xorg.libX11 xorg.libXcomposite xorg.libXdamage xorg.libXext
    xorg.libXfixes xorg.libXrandr xorg.libxcb
    alsa-lib at-spi2-atk at-spi2-core atk cairo cups dbus expat
    gdk-pixbuf glib gtk3 libdrm libxkbcommon mesa nspr nss pango systemd
  ];

  virtualisation.vmVariant = {
    virtualisation.memorySize = memorySize;
    virtualisation.cores = cores;
    virtualisation.diskSize = diskSize;
    virtualisation.graphics = false;

    virtualisation.forwardPorts = [
      { from = "host"; host.port = sshPortForward; guest.port = 22; }
    ];

    # Share the project source from the host into the VM.
    # `self` is the flake's own source path, threaded in via specialArgs.
    virtualisation.sharedDirectories = lib.mkIf (self != null) {
      project = {
        source = builtins.toString self;
        target = "/home/dev/project";
      };
    };
  };

  environment.sessionVariables = {
    PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright-driver.browsers}";
    PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";
  };
}
