{
  description = "Zig 0.16 dev env (native + NixOS VM) with AI coding tools, Apalache, and agent-browser";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    # mitchellh/zig-overlay tracks every Zig release (and master).
    zig-overlay = {
      url = "github:mitchellh/zig-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ZLS (Zig Language Server) — official flake.
    zls = {
      url = "github:zigtools/zls";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, zig-overlay, zls, ... }:
    let
      vmSystem = "x86_64-linux";

      # Pick the Zig package per system. zig-overlay exposes
      # `<system>.master` (latest dev) and pinned versions like `<system>."0.16.0"`.
      # 0.16 isn't tagged yet — use master until it is.
      zigFor = system: zig-overlay.packages.${system}.master;
      zlsFor = system: zls.packages.${system}.default;
    in
    {
      nixosConfigurations.dev-vm = nixpkgs.lib.nixosSystem {
        system = vmSystem;
        specialArgs = { inherit self; };
        modules = [
          (import ./_lib/vm-module.nix {
            hostname = "dev-vm";
            extraPackages = pkgs: [
              (zigFor vmSystem)
              (zlsFor vmSystem)
            ] ++ (with pkgs; [ lldb gdb ]);
          })
        ];
      };
    }
    //
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        sharedTools = import ./_lib/shared-tools.nix { inherit pkgs; };

        zig = zigFor system;
        zlsPkg = zlsFor system;
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            zig
            zlsPkg
          ] ++ (with pkgs; [
            lldb
            gdb
            neovim just
            pkg-config
          ])
          ++ sharedTools.aiCodingTools
          ++ sharedTools.formalVerificationTools;

          shellHook = ''
            echo "⚡ Zig $(zig version)  /  ZLS $(zls --version 2>&1 | head -n1)"
            echo "Run 'just' for project tasks, 'just vm' to start the NixOS VM."
            export PLAYWRIGHT_BROWSERS_PATH="${pkgs.playwright-driver.browsers}"
            export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
          '';
        };
      });
}
