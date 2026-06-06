{
  description = "Python dev env (native + NixOS VM) with uv, AI coding tools, Apalache, and agent-browser";

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
              python314
              python314Packages.uv
              python314Packages.pip
              python314Packages.virtualenv
              ruff
              pyright
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

        pythonEnv = pkgs.python314;
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = (with pkgs; [
            pythonEnv

            # Package management
            python314Packages.uv
            python314Packages.pip
            python314Packages.setuptools
            python314Packages.wheel
            python314Packages.build
            python314Packages.twine

            # Testing
            python314Packages.pytest
            python314Packages.pytest-cov
            python314Packages.pytest-asyncio
            python314Packages.pytest-xdist
            python314Packages.hypothesis

            # Lint / format / type-check
            ruff
            python314Packages.mypy
            python314Packages.black
            python314Packages.isort

            # Language Server
            pyright
            python314Packages.python-lsp-server
            python314Packages.pylsp-mypy
            python314Packages.python-lsp-ruff

            # Type stubs
            python314Packages.types-requests
            python314Packages.types-setuptools

            # Docs
            python314Packages.sphinx
            python314Packages.sphinx-rtd-theme

            # Debug / REPL
            python314Packages.ipdb
            python314Packages.ipython

            # Editor / runner
            neovim
            just

            # System libs commonly needed for native wheels
            gcc gnumake pkg-config openssl libffi zlib
          ])
          ++ sharedTools.aiCodingTools
          ++ sharedTools.formalVerificationTools;

          shellHook = ''
            echo "🐍 Python $(python --version 2>&1 | awk '{print $2}') / uv $(uv --version 2>&1 | awk '{print $2}') / ruff $(ruff --version 2>&1 | awk '{print $2}')"
            echo "Run 'just' to list project tasks, 'just vm' to spin up the NixOS VM."
            export PLAYWRIGHT_BROWSERS_PATH="${pkgs.playwright-driver.browsers}"
            export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
          '';

          PYTHONPATH = ".";
          UV_CACHE_DIR = ".uv-cache";
        };
      });
}
