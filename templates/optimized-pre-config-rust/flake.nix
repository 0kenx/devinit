{
  description = "Rust dev env (native + NixOS VM) with AI coding tools, Apalache, and agent-browser";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    crane.url = "github:ipetkov/crane";

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    advisory-db = {
      url = "github:rustsec/advisory-db";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, crane, rust-overlay, advisory-db, ... }:
    let
      vmSystem = "x86_64-linux";
    in
    {
      # ───────────────────────────── NixOS VM ─────────────────────────────
      # Run with `just vm`.
      nixosConfigurations.dev-vm = nixpkgs.lib.nixosSystem {
        system = vmSystem;
        specialArgs = { inherit self; };
        modules = [
          (import ./_lib/vm-module.nix {
            hostname = "dev-vm";
            extraOverlays = [ (import rust-overlay) ];
            extraPackages = pkgs: with pkgs; [
              (rust-bin.fromRustupToolchainFile ./rust-toolchain.toml)
              rust-analyzer
              cargo-nextest
              cargo-watch
              cargo-edit
              sccache
              mold
              bacon
              llvmPackages.libclang
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
          overlays = [ (import rust-overlay) ];
          config.allowUnfree = true;
        };

        inherit (pkgs) lib;

        sharedTools = import ./_lib/shared-tools.nix { inherit pkgs; };

        rustToolchain = pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
        craneLib = (crane.mkLib pkgs).overrideToolchain rustToolchain;

        cargoLockExists = builtins.pathExists ./Cargo.lock;
        src = if cargoLockExists then craneLib.cleanCargoSource (craneLib.path ./.) else ./.;

        commonArgs = {
          inherit src;
          strictDeps = true;
          nativeBuildInputs = [ pkgs.pkg-config ];
          buildInputs = [ pkgs.openssl pkgs.taplo ]
            ++ lib.optionals pkgs.stdenv.isDarwin [ pkgs.libiconv ];
        };

        cargoArtifacts = if cargoLockExists then craneLib.buildDepsOnly commonArgs else null;
        my-crate = if cargoLockExists then craneLib.buildPackage (commonArgs // { inherit cargoArtifacts; }) else null;
      in
      {
        checks = lib.optionalAttrs cargoLockExists {
          inherit my-crate;
          my-crate-clippy = craneLib.cargoClippy (commonArgs // {
            inherit cargoArtifacts;
            cargoClippyExtraArgs = "--all-targets -- --deny warnings";
          });
          my-crate-doc = craneLib.cargoDoc (commonArgs // { inherit cargoArtifacts; });
          my-crate-fmt = craneLib.cargoFmt { inherit src; };
          my-crate-audit = craneLib.cargoAudit { inherit src advisory-db; };
          my-crate-deny = craneLib.cargoDeny { inherit src; };
          my-crate-nextest = craneLib.cargoNextest (commonArgs // {
            inherit cargoArtifacts;
            partitions = 1;
            partitionType = "count";
          });
        };

        packages = lib.optionalAttrs cargoLockExists { default = my-crate; };
        apps = lib.optionalAttrs cargoLockExists {
          default = flake-utils.lib.mkApp { drv = my-crate; };
        };

        devShells.default = craneLib.devShell {
          checks = self.checks.${system};

          shellHook = ''
            export LIBCLANG_PATH="${pkgs.llvmPackages.libclang.lib}/lib"
            export RUSTC_WRAPPER="${pkgs.sccache}/bin/sccache"
            export PLAYWRIGHT_BROWSERS_PATH="${pkgs.playwright-driver.browsers}"
            export PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1
          '';

          packages = (with pkgs; [
            rust-analyzer
            cargo-watch cargo-deny cargo-audit cargo-update cargo-edit
            cargo-outdated cargo-license cargo-tarpaulin cargo-zigbuild
            cargo-nextest cargo-spellcheck cargo-modules cargo-bloat
            cargo-unused-features
            sccache mold bacon
            llvmPackages.libclang
            pkg-config openssl
            just neovim
          ]) ++ sharedTools.aiCodingTools ++ sharedTools.formalVerificationTools;
        };
      });
}
