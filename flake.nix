{
  description = "Smash Ultimate skyline mod to use custom Minecraft skins";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
    nix-skyline-rs = {
      url = "github:Naxdy/nix-skyline-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, flake-utils, nix-skyline-rs, nixpkgs, ... }@inputs:
  (flake-utils.lib.eachDefaultSystem (system: let
    pkgs = import nixpkgs { inherit system; };
    cargoTOML = builtins.fromTOML (builtins.readFile ./Cargo.toml);
  in {
    packages = {
      default = self.packages.${system}.smash-minecraft-skins;
      smash-minecraft-skins = pkgs.callPackage ({ 
        mode              ? "build",
        copyLibs          ? true,
        cargoBuildOptions ? old: old,
        overrideMain      ? old: old
      }: nix-skyline-rs.lib.${system}.mkNroPackage {
        inherit cargoBuildOptions overrideMain mode copyLibs;
        inherit (cargoTOML.package) version;
        pname   = cargoTOML.package.name;
        src = self;
      }) {};
    };

    devShells.default = nix-skyline-rs.devShells.${system}.default;
    checks = {
      clippy = self.packages.${system}.smash-minecraft-skins.override { mode = "clippy"; };
    };
  }));
}
