{
  description = "THXNET. Leafchains";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    crane.url = "github:ipetkov/crane";
  };

  outputs = { self, nixpkgs, flake-utils, fenix, crane }:
    let
      name = "thxnet-leafchains";
      version = "0.1.0";
    in
    (flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [
              self.overlays.default
              fenix.overlays.default
            ];
          };

          rustToolchain = fenix.packages.${system}.fromToolchainFile {
            file = ./rust-toolchain.toml;
            sha256 = "sha256-6HXUaEJQRPTsvpgw7T0jS47IuIz8UmjsTXl/Fx/5n3o=";
          };

          rustPlatform = pkgs.makeRustPlatform {
            cargo = rustToolchain;
            rustc = rustToolchain;
          };

          craneLib = (crane.mkLib pkgs).overrideToolchain rustToolchain;

          cargoArgs = [
            "--workspace"
            "--bins"
            "--examples"
            "--tests"
            "--benches"
            "--all-targets"
          ];

          unitTestArgs = [
            "--workspace"
          ];

          src = craneLib.cleanCargoSource (craneLib.path ./.);
          commonArgs = {
            inherit src;

            nativeBuildInputs = with pkgs; [
              llvmPackages_14.clang
              llvmPackages_14.libclang
            ];

            PROTOC = "${pkgs.protobuf}/bin/protoc";
            PROTOC_INCLUDE = "${pkgs.protobuf}/include";

            LIBCLANG_PATH = "${pkgs.llvmPackages_14.libclang.lib}/lib";

            SUBSTRATE_CLI_GIT_COMMIT_HASH = "";
          };
          cargoArtifacts = craneLib.buildDepsOnly commonArgs;
        in
        rec {
          formatter = pkgs.treefmt;

          devShells.default = pkgs.callPackage ./devshell {
            inherit rustToolchain cargoArgs unitTestArgs;
          };

          packages = rec {
            default = thxnet-leafchain;
            thxnet-leafchain = pkgs.callPackage ./devshell/package.nix {
              inherit name version rustPlatform;
            };
            container = pkgs.callPackage ./devshell/container.nix {
              inherit name version thxnet-leafchain;
            };
          };

          apps.default = flake-utils.lib.mkApp {
            drv = packages.thxnet-leafchain;
            exePath = "/bin/thxnet-leafchain";
          };

          checks = {
            format = pkgs.callPackage ./devshell/format.nix { };

            rust-build = craneLib.cargoBuild (commonArgs // {
              inherit cargoArtifacts;
            });
            rust-format = craneLib.cargoFmt { inherit src; };
            rust-clippy = craneLib.cargoClippy (commonArgs // {
              inherit cargoArtifacts;
              cargoClippyExtraArgs = pkgs.lib.strings.concatMapStrings (x: x + " ") cargoArgs;
            });
            rust-nextest = craneLib.cargoNextest (commonArgs // {
              inherit cargoArtifacts;
              partitions = 1;
              partitionType = "count";
            });
          };
        })) // {
      overlays.default = final: prev: {
        thxnet-leafchain = final.callPackage ./devshell/package.nix {
          inherit name version;
        };
      };
    };
}
