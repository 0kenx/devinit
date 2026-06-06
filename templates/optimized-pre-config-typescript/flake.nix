{
  description = "TypeScript + Bun dev env (native + NixOS VM) with AI coding tools, Apalache, and agent-browser";

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
              bun
              nodejs_24
              typescript
              biome
              nodePackages.typescript-language-server
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
            # Bun is the primary runtime; Node provided for compat with tools.
            bun
            nodejs_24

            # Languages / formatting / linting
            typescript
            biome
            nodePackages.prettier
            nodePackages.eslint

            # LSPs
            nodePackages.typescript-language-server
            nodePackages.vscode-langservers-extracted

            # Editor / runner
            neovim just
          ])
          ++ sharedTools.aiCodingTools
          ++ sharedTools.formalVerificationTools;

          shellHook = ''
            echo "🥟 Bun $(bun --version)  /  TypeScript $(tsc --version | awk '{print $2}')"
            echo "Run 'just' for project tasks, 'just vm' to start the NixOS VM."
            export PLAYWRIGHT_BROWSERS_PATH="${pkgs.playwright-driver.browsers}"
            export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
          '';
        };
      });
}
