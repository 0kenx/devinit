{
  description = "Elixir / Erlang dev env (native + NixOS VM) with AI coding tools, Apalache, and agent-browser";

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
            extraPackages = pkgs: with pkgs.beam.packages.erlang_29; [
              elixir
              erlang
              elixir-ls
            ] ++ (with pkgs; [ rebar3 inotify-tools ]);
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

        # Pin to Erlang/OTP 29 (latest stable as of nixpkgs-unstable).
        beamPkgs = pkgs.beam.packages.erlang_29;
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            beamPkgs.elixir
            beamPkgs.erlang
            beamPkgs.elixir-ls
            beamPkgs.rebar3
          ] ++ (with pkgs; [
            inotify-tools     # for Phoenix file watching
            postgresql        # common dep for Phoenix/Ecto
            neovim just
            gcc gnumake pkg-config openssl
          ])
          ++ sharedTools.aiCodingTools
          ++ sharedTools.formalVerificationTools;

          shellHook = ''
            echo "💜 Elixir $(elixir --version | tail -n1) / Erlang $(erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().' -noshell 2>/dev/null)"
            echo "Run 'just' for project tasks, 'just vm' to start the NixOS VM."
            export PLAYWRIGHT_BROWSERS_PATH="${pkgs.playwright-driver.browsers}"
            export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
            export MIX_HOME="$PWD/.mix"
            export HEX_HOME="$PWD/.hex"
            export PATH="$MIX_HOME/escripts:$PATH"
          '';
        };
      });
}
