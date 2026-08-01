{ inputs, pkgs, ... }:
let
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

  hunk = inputs.hunk.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  home.packages = [
    portless
    hunk
  ];
}
