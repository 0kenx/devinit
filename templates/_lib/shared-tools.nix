# Shared AI coding tools, agent-browser, and Apalache.
# Mirrors the patterns from ~/git/nixos-dotfiles/nixos/modules/ai/coding.nix.
{ pkgs }:

let
  inherit (pkgs) stdenv;

  mkLazyNpm =
    { binName
    , pkgName
    , exec
    }:
    pkgs.writeShellScriptBin binName ''
      export PATH="${pkgs.nodejs_26}/bin:$PATH"
      export HOME="''${HOME:-/tmp}"
      export npm_config_cache="$HOME/.cache/${binName}-npm"

      INSTALL_DIR="$HOME/.local/share/${binName}-nix"
      if [ ! -f "$INSTALL_DIR/node_modules/.package-lock.json" ]; then
        mkdir -p "$INSTALL_DIR"
        cd "$INSTALL_DIR"
        cat > package.json << 'PKGJSON'
      {
        "name": "${binName}-nix",
        "private": true,
        "dependencies": {
          "${pkgName}": "latest"
        }
      }
      PKGJSON
        npm install 2>/dev/null
      fi

      ${exec}
    '';

  agent-browser = mkLazyNpm {
    binName = "agent-browser";
    pkgName = "agent-browser";
    exec = ''
      exec env \
        PLAYWRIGHT_BROWSERS_PATH="${pkgs.playwright-driver.browsers}" \
        PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1 \
        NODE_PATH="$INSTALL_DIR/node_modules" \
        node "$INSTALL_DIR/node_modules/agent-browser/bin/agent-browser.js" "$@"
    '';
  };

  codex = mkLazyNpm {
    binName = "codex";
    pkgName = "@openai/codex";
    exec = ''exec node "$INSTALL_DIR/node_modules/@openai/codex/bin/codex.js" "$@"'';
  };

  apalache = stdenv.mkDerivation rec {
    pname = "apalache";
    version = "0.52.2";

    src = pkgs.fetchurl {
      url = "https://github.com/apalache-mc/apalache/releases/download/v${version}/apalache-${version}.tgz";
      sha256 = "e0ebea7e45c8f99df8d92f2755101dda84ab71df06d1ec3a21955d3b53a886e2";
    };

    nativeBuildInputs = [ pkgs.makeWrapper ];
    buildInputs = [ pkgs.jdk21_headless ];

    dontConfigure = true;
    dontBuild = true;

    unpackPhase = ''
      mkdir -p src
      tar xzf $src -C src --strip-components=1
    '';

    installPhase = ''
      mkdir -p $out/share/apalache $out/bin
      cp -r src/lib $out/share/apalache/
      cp -r src/bin $out/share/apalache/
      makeWrapper $out/share/apalache/bin/apalache-mc $out/bin/apalache-mc \
        --set JAVA_HOME "${pkgs.jdk21_headless}" \
        --prefix PATH : "${pkgs.jdk21_headless}/bin"
    '';
  };
in
{
  inherit agent-browser codex apalache;

  # Full AI coding-tool kit, mirroring nixos/modules/ai/coding.nix.
  # claude-code and opencode are native nixpkgs; codex is an npm wrapper
  # so it stays on `@latest`.
  aiCodingTools = [
    pkgs.claude-code
    pkgs.opencode
    codex
    agent-browser
  ];

  # Formal-verification kit: Apalache + Quint + Z3 + TLA+ tools.
  formalVerificationTools = [
    apalache
    pkgs.quint
    pkgs.z3
    pkgs.tlaplus
  ];
}
