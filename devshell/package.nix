{ name
, version
, lib
, rustPlatform
, llvmPackages_14
, protobuf
}:

rustPlatform.buildRustPackage {
  pname = name;
  inherit version;

  src = lib.cleanSource ./..;

  cargoLock = {
    lockFile = ../Cargo.lock;
    outputHashes = {
      # v0.9.43 hashes - same as rootchain
      "binary-merkle-tree-4.0.0-dev" = "sha256-YxCAFrLWTmGjTFzNkyjE+DNs2cl4IjAlB7qz0KPN1vE=";
      "cumulus-client-cli-0.1.0" = "sha256-mlhTYigfROBq11OWZMLwwEyMwE1hp8x+ShMj1mpiH9g=";
      "kusama-runtime-0.9.43" = "sha256-sjamgp7VaL+DeG1gWTFbcz5szjQl2tyfLZH7oTflhcw=";
    };
  };

  nativeBuildInputs = [
    llvmPackages_14.clang
    llvmPackages_14.libclang
  ];

  doCheck = false;

  PROTOC = "${protobuf}/bin/protoc";
  PROTOC_INCLUDE = "${protobuf}/include";

  LIBCLANG_PATH = "${llvmPackages_14.libclang.lib}/lib";

  SUBSTRATE_CLI_GIT_COMMIT_HASH = "";

  CARGO_NET_OFFLINE = "true";
}
