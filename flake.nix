{
  description = "SmartNav path follower module";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    lcm-extended = {
      url = "github:jeff-hykin/lcm_extended";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    dimos-lcm = {
      url = "github:dimensionalOS/dimos-lcm/main";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, lcm-extended, dimos-lcm, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        lcm = lcm-extended.packages.${system}.lcm;

        # Disable PCL's OpenNI grabbers. PCL 1.15.1's CMake auto-enables
        # WITH_OPENNI on Linux without putting the openni package on the
        # include path, so io/openni_camera/openni.h fails to find XnOS.h.
        # We don't use the grabber.
        pcl = pkgs.pcl.overrideAttrs (old: {
          cmakeFlags = (old.cmakeFlags or []) ++ [
            "-DWITH_OPENNI=OFF"
            "-DWITH_OPENNI2=OFF"
          ];
        });
      in {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "smartnav-path-follower";
          version = "0.1.0";
          src = ./.;

          nativeBuildInputs = [ pkgs.cmake pkgs.pkg-config ];
          buildInputs = [ lcm pkgs.glib pkgs.eigen pkgs.boost pcl ];

          cmakeFlags = [
            "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
            "-DFETCHCONTENT_SOURCE_DIR_DIMOS_LCM=${dimos-lcm}"
          ];
        };
      });
}
