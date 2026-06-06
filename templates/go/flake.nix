{
  description = "Go dev env (native + NixOS VM) with AI coding tools, Apalache, and agent-browser";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    let
      vmSystem = "x86_64-linux";
    in
    {
      nixosConfigurations.dev-vm = nixpkgs.lib.nixosSystem {
        system = vmSystem;
        specialArgs = { inherit self; };
        modules = [
          (import ./_lib/vm-module.nix {
            hostname = "dev-vm";
            extraPackages = pkgs: with pkgs; [
              go
              gopls
              gotools
              go-tools
              delve
              golangci-lint
            ];
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
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = (with pkgs; [
            # Latest Go (nixpkgs-unstable tracks latest stable).
            go

            # Tooling
            gopls                 # LSP
            gotools               # goimports, godoc, etc.
            go-tools              # staticcheck
            golangci-lint
            delve                 # debugger
            gomodifytags
            gotests
            impl
            mockgen

            # Editor / runner
            neovim just

            # System libs commonly needed for cgo
            gcc gnumake pkg-config openssl
          ])
          ++ sharedTools.aiCodingTools
          ++ sharedTools.formalVerificationTools;

          shellHook = ''
            echo "🐹 $(go version)"
            echo "Run 'just' for project tasks, 'just vm' to start the NixOS VM."
            export PLAYWRIGHT_BROWSERS_PATH="${pkgs.playwright-driver.browsers}"
            export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
            # Keep module cache local to the project so .direnv stays self-contained.
            export GOPATH="$PWD/.gopath"
            export GOCACHE="$PWD/.gocache"
            export PATH="$GOPATH/bin:$PATH"
          '';
        };
      });
}
