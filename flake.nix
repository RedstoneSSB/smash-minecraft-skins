{
  description = "Smash Ultimate skyline mod to use custom Minecraft skins";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
    nix-skyline-rs = {
      url = "github:Naxdy/nix-skyline-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-std.url = "github:chessai/nix-std";
  };
  outputs = { self, flake-utils, nix-skyline-rs, nixpkgs, nix-std, ... }@inputs: 
  {
    lib = {
      nixpkgs = nixpkgs.lib;
      std = inputs.nix-std.lib;
    };
  } //
  (flake-utils.lib.eachDefaultSystem (system: let
    pkgs = import nixpkgs { inherit system; };
    packages = self.packages.${system};
    inherit ((builtins.fromTOML (builtins.readFile ./Cargo.toml)).package) authors name version;
    plugName = "lib${builtins.replaceStrings ["-"] ["_"] name}.nro";
  in {
    lib = {
      mkInfoToml = path-info-toml-base: path-cargo-toml: let
        info-base = builtins.fromTOML (builtins.readFile path-info-toml-base);
        cargo     = (builtins.fromTOML (builtins.readFile path-cargo-toml)).package;
        info = info-base // {
          inherit (cargo) name version; 
          authors = builtins.concatStringsSep ", " cargo.authors;
        };
      in (pkgs.formats.toml {}).generate "info.toml" info;
    };
    packages = {
      default = packages.nro;
      nro = pkgs.stdenv.mkDerivation {
        inherit version;
        pname = name + "-nro";
        src = (nix-skyline-rs.lib.${system}.mkNroPackage {
          inherit version;
          pname = name;
          src = self;
          mode = "build";
          copyLibs = true;
        });
        installPhase = ''
          mkdir -p $out
          cp $src/lib/${plugName} $out
          chmod u+rx $out/${plugName}
        '';
      };
      arcropolis-dir = pkgs.stdenv.mkDerivation {
        inherit version;
        pname = name;
        src = ./assets;
        installPhase = ''
          mkdir -p $out/minecraft_skins
          ln -s $src/* $out
          unlink $out/info.toml
          ln -sf ${self.lib.${system}.mkInfoToml ./assets/info.toml ./Cargo.toml} $out/info.toml
          ln -s  ${packages.nro}/${plugName} $out/plugin.nro
        '';
      };
      arcropolis-zip = pkgs.stdenv.mkDerivation {
        inherit version;
        pname = name + "-ARCropolis-zip";
        src = packages.arcropolis-dir;
        nativeBuildInputs = [pkgs.zip];
        buildPhase = ''
          mkdir -p      ./ultimate/mods/${name}
          cp -r $src/*  ./ultimate/mods/${name}
        '';
        installPhase = ''
          mkdir -p $out
          zip -r $out/${name}.zip ./ultimate
        '';
      };
    };

    devShells.default = nix-skyline-rs.devShells.${system}.default;

    # FIXME: No such package anymore
    checks = {
      clippy = self.packages.${system}.smash-minecraft-skins.override { mode = "clippy"; };
    };
  }));
}
