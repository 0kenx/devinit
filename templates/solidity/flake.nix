{
  description = "Solidity dev env (native + NixOS VM) with Foundry, Certora, AI coding tools, Apalache, and agent-browser";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    foundry.url = "github:shazow/foundry.nix/monthly";
  };

  outputs = { self, nixpkgs, flake-utils, foundry, ... }:
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
            extraOverlays = [ foundry.overlay ];
            extraPackages = pkgs: with pkgs; [
              foundry-bin
              solc
              slither-analyzer
              python313        # newest Python in certora-cli's supported range (<3.14)
              python313Packages.uv
              jq lcov
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
          overlays = [ foundry.overlay ];
          config.allowUnfree = true;
        };

        sharedTools = import ./_lib/shared-tools.nix { inherit pkgs; };

        # Certora CLI is a Python tool installed lazily via uv. Run `just install-certora`
        # to install/upgrade it into ./.certora-venv, then use `certoraRun` from the shell.
        # Python 3.13 is the newest currently in certora-cli's supported range (>=3.8.16,<3.14).
        #
        # `--no-project` on `uv venv` skips any host pyproject.toml so the
        # venv's interpreter is selected independently of the project's
        # `requires-python`. `uv pip install` is pip-compatible and never
        # reads pyproject.toml, so it doesn't need (or accept) `--no-project`.
        certora-installer = pkgs.writeShellScriptBin "install-certora" ''
          set -e
          export PATH="${pkgs.python313}/bin:${pkgs.python313Packages.uv}/bin:$PATH"
          VENV=".certora-venv"
          if [ ! -d "$VENV" ]; then
            echo "Creating Python 3.13 venv at $VENV..."
            uv venv --no-project --python 3.13 "$VENV"
          fi
          echo "Installing/upgrading certora-cli..."
          uv pip install --python "$VENV/bin/python" --upgrade certora-cli
          echo ""
          echo "✓ Certora CLI installed."
          echo "  Activate: source $VENV/bin/activate.fish   (or .../bin/activate)"
          echo "  Then run: certoraRun --help"
        '';
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = (with pkgs; [
            # Foundry suite (forge, cast, anvil, chisel)
            foundry-bin
            solc

            # Static analysis
            slither-analyzer

            # Certora: Python 3.13 + uv + installer helper (see `install-certora`)
            python313
            python313Packages.uv

            # Solidity LSP deps
            nodejs_26
            vscode-langservers-extracted

            # Dev tools
            lcov jq
            neovim just
          ])
          ++ [ certora-installer ]
          ++ sharedTools.aiCodingTools
          ++ sharedTools.formalVerificationTools;

          shellHook = ''
            # Solidity LSP (installs into ./node_modules on first entry)
            if [ ! -d "node_modules/@nomicfoundation/solidity-language-server" ]; then
              echo "Installing Solidity Language Server..."
              npm install --save-dev @nomicfoundation/solidity-language-server >/dev/null 2>&1 || true
            fi
            export PATH="$PWD/node_modules/.bin:$PWD/.certora-venv/bin:$PATH"

            echo "🔨 Foundry: $(forge --version 2>&1 | head -n1)"
            echo "    solc:    $(solc --version 2>&1 | grep -i version | head -n1)"
            echo ""
            echo "Run 'just' for project tasks, 'just vm' to start the NixOS VM."
            echo "Run 'install-certora' once to install Certora CLI."
            export PLAYWRIGHT_BROWSERS_PATH="${pkgs.playwright-driver.browsers}"
            export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
          '';
        };
      });
}
