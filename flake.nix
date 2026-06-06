{
  description = "Standalone project-template initializer";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
          package = pkgs.stdenvNoCC.mkDerivation {
            pname = "devinit";
            version = "0.1.0";
            src = self;

            nativeBuildInputs = [
              pkgs.makeWrapper
            ];

            dontBuild = true;
            doCheck = true;

            checkPhase = ''
              runHook preCheck
              bash -n devinit
              ./devinit --list >/dev/null
              runHook postCheck
            '';

            installPhase = ''
              runHook preInstall
              install -Dm755 devinit "$out/libexec/devinit/devinit"
              cp -a templates "$out/libexec/devinit/templates"
              patchShebangs "$out/libexec/devinit/devinit"
              makeWrapper "$out/libexec/devinit/devinit" "$out/bin/devinit" \
                --prefix PATH : "${
                  pkgs.lib.makeBinPath [
                    pkgs.bash
                    pkgs.coreutils
                    pkgs.findutils
                    pkgs.git
                    pkgs.direnv
                  ]
                }"
              runHook postInstall
            '';

            meta = {
              description = "Standalone project-template initializer";
              mainProgram = "devinit";
              platforms = pkgs.lib.platforms.unix;
            };
          };
        in
        {
          default = package;
          devinit = package;
        }
      );

      apps = forAllSystems (system: {
        default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/devinit";
        };
      });

      formatter = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        pkgs.nixfmt-rfc-style
      );
    };
}
