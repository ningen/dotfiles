{ inputs, pkgs, lib, ... }:
let
  # OpenCode 2 is currently distributed as platform-specific native npm
  # packages rather than a package in nixpkgs. Keep the beta version pinned
  # here so Home Manager does not fetch or update it at runtime.
  opencode2Version = "0.0.0-beta-18684";
  opencode2Target =
    if pkgs.stdenv.hostPlatform.system == "aarch64-darwin" then
      {
        packageName = "cli-darwin-arm64";
        hash = "sha256-FEhbtAKyo1tdxqLC/1N+tQ9re96MOd35zzGryup5jso=";
      }
    else if pkgs.stdenv.hostPlatform.system == "x86_64-linux" then
      {
        packageName = "cli-linux-x64-baseline";
        hash = "sha256-KkpcAV4LcLuk/O8VF2IU4KCnzBwrrmySxsoA3tO8QHs=";
      }
    else
      throw "opencode2 is not supported on ${pkgs.stdenv.hostPlatform.system}";

  opencode2 = pkgs.stdenvNoCC.mkDerivation {
    pname = "opencode2";
    version = opencode2Version;

    src = pkgs.fetchurl {
      url = "https://registry.npmjs.org/@opencode-ai/${opencode2Target.packageName}/-/${opencode2Target.packageName}-${opencode2Version}.tgz";
      hash = opencode2Target.hash;
    };

    nativeBuildInputs = lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.patchelf ];

    dontConfigure = true;
    dontBuild = true;
    # autoPatchelfHook/patchelf's normal RPATH fixups break Bun's embedded app.
    # Patch only the ELF interpreter below. Do NOT inject LD_LIBRARY_PATH in the
    # launcher: Bun is essentially static, and a leaked LD_LIBRARY_PATH (pointing
    # at Nix glibc) makes OpenCode's shell tool crash a DIFERENT glibc's /bin and
    # /usr/bin binaries (e.g. ssh, cat, ls) with SIGSEGV.
    dontFixup = true;

    installPhase = ''
      install -Dm755 bin/opencode2 "$out/libexec/opencode2"
      ${lib.optionalString pkgs.stdenv.hostPlatform.isLinux ''
        patchelf --set-interpreter ${pkgs.glibc}/lib/ld-linux-x86-64.so.2 "$out/libexec/opencode2"
        mkdir -p "$out/bin"
        cat > "$out/bin/opencode2" <<EOF
        #!${pkgs.runtimeShell}
        exec "$out/libexec/opencode2" "\$@"
        EOF
        chmod 755 "$out/bin/opencode2"
      ''}
      ${lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''
        install -Dm755 bin/opencode2 "$out/bin/opencode2"
      ''}
    '';

    meta = {
      description = "OpenCode 2 beta coding agent for the terminal";
      homepage = "https://opencode.ai";
      license = lib.licenses.mit;
      mainProgram = "opencode2";
      platforms = [ "aarch64-darwin" "x86_64-linux" ];
    };
  };

  portless = pkgs.buildNpmPackage rec {
    pname = "portless";
    version = "0.15.5";

    src = pkgs.fetchurl {
      url = "https://registry.npmjs.org/portless/-/portless-${version}.tgz";
      hash = "sha512-zmJu4Q8/fY54oVUT/5NnmF4Ih8wTdCvCf6JCN783dRYl9mXkJBzXSckX2lztGCLIbM70varDjCudAbGKT73XPg==";
    };

    postPatch = ''
      cat > package.json <<'EOF'
      {
        "name": "portless",
        "version": "0.15.5",
        "description": "Replace port numbers with stable, named .localhost URLs. For humans and agents.",
        "type": "module",
        "main": "./dist/index.js",
        "types": "./dist/index.d.ts",
        "exports": {
          ".": {
            "import": "./dist/index.js",
            "types": "./dist/index.d.ts"
          }
        },
        "bin": {
          "portless": "./dist/cli.js"
        },
        "files": [
          "dist"
        ],
        "engines": {
          "node": ">=24"
        },
        "os": [
          "darwin",
          "linux",
          "win32"
        ],
        "keywords": [
          "local",
          "development",
          "proxy",
          "localhost"
        ],
        "author": "Vercel Labs",
        "license": "Apache-2.0",
        "repository": {
          "type": "git",
          "url": "https://github.com/vercel-labs/portless.git"
        },
        "homepage": "https://portless.sh",
        "bugs": {
          "url": "https://github.com/vercel-labs/portless/issues"
        }
      }
      EOF

      cat > package-lock.json <<'EOF'
      {
        "name": "portless",
        "version": "0.15.5",
        "lockfileVersion": 3,
        "requires": true,
        "packages": {
          "": {
            "name": "portless",
            "version": "0.15.5",
            "license": "Apache-2.0",
            "bin": {
              "portless": "./dist/cli.js"
            },
            "engines": {
              "node": ">=24"
            },
            "os": [
              "darwin",
              "linux",
              "win32"
            ]
          }
        }
      }
      EOF
    '';

    npmDepsHash = "sha256-NhuqCS86DhwOi+MLdW2JhtLR2eaObPBbGHKi52nW4TY=";
    forceEmptyCache = true;
    dontNpmBuild = true;
    postConfigure = ''
      mkdir -p node_modules
    '';
    preInstall = ''
      mkdir -p node_modules
    '';

    meta = {
      description = "Replace port numbers with stable, named .localhost URLs";
      homepage = "https://portless.sh";
      license = pkgs.lib.licenses.asl20;
      mainProgram = "portless";
      platforms = pkgs.lib.platforms.unix;
    };
  };

  pencli = pkgs.buildNpmPackage rec {
    pname = "pencli";
    version = "0.3.3";

    src = pkgs.fetchurl {
      url = "https://registry.npmjs.org/@pen.dev/cli/-/cli-${version}.tgz";
      hash = "sha512-/JT7Ir3KelG0G5V7lfvpciWTTOa205IfqS/iMVT8XhbGc25Llo1D1nAooEffh9gMgVdOD9oWKPDeIGnYhHcAtQ==";
    };

    dontNpmBuild = true;
    npmDepsHash = "sha256-h/Ru2VirjXfF5cXuafRA5VRGJLJWNi/PBVSJUrlnFFQ=";
    postPatch = ''
      cp ${./locks/pencli/package-lock.json} package-lock.json
    '';

    meta = {
      description = "CLI tool for running the pen.dev AI agent manipulating .pen design files";
      homepage = "https://pen.dev";
      mainProgram = "pen";
      platforms = pkgs.lib.platforms.unix;
    };
  };

  hunk = inputs.hunk.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  home.packages = [
    opencode2
    portless
    pencli
    hunk
  ];
}
