{
  inputs = {
    nixpkgs.url = "github:aca/nixpkgs?ref=oci-aarch64-darwin";
    gomod2nix = {
      url = "github:nix-community/gomod2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sbomnix = {
      url = "github:tiiuae/sbomnix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    gomod2nix,
    sbomnix,
  }: let
    allSystems = [
      "x86_64-linux" # 64-bit Intel/AMD Linux
      "aarch64-linux" # 64-bit ARM Linux
      "x86_64-darwin" # 64-bit Intel macOS
      "aarch64-darwin" # 64-bit ARM macOS
    ];

    forAllSystems = f:
      nixpkgs.lib.genAttrs allSystems (system:
        f {
          inherit system;
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        });
  in {
    packages = forAllSystems ({
      system,
      pkgs,
      ...
    }: let
      buildGoApplication = gomod2nix.legacyPackages.${system}.buildGoApplication;
    in rec {
      default = buildGoApplication rec {
        name = "fep";
        go = pkgs.go_1_22;
        src = ./.;
        subPackages = ["."];

        # postFixup = nixpkgs.lib.optionalString pkgs.stdenv.isLinux ''
        #   patchelf $out/bin/fep --add-rpath ${pkgs.lib.makeLibraryPath [ pkgs.oracle-instantclient.lib pkgs.nss]}
        # '';

        # postFixup = nixpkgs.lib.optionalString pkgs.stdenv.isLinux ''
        #   patchelf $out/bin/fep --add-rpath ${pkgs.lib.makeLibraryPath [pkgs.oracle-instantclient.lib pkgs.nss]}
        # '';

        propagatedBuildInputs = with pkgs; [
          # pkgs.toybox
          # pkgs.strace
        ];

        # tags = [
        # ];

        nativeBuildInputs = with pkgs; [
        ];

        pwd = ./.;

        doCheck = false;
      };
    });

    devShells = forAllSystems ({
      system,
      pkgs,
    }: {
      default = pkgs.mkShell {
        # on MacOS, install oracle-instantclient with brew
        shellHook = if pkgs.stdenv.isLinux then ''
          export LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath [pkgs.oracle-instantclient]};
          export INCLUDE_PATH=${pkgs.lib.strings.makeIncludePath [pkgs.oracle-instantclient]};
        '' else ''
          export DYLD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath [pkgs.oracle-instantclient]};
          export INCLUDE_PATH=${pkgs.lib.strings.makeIncludePath [pkgs.oracle-instantclient]};
        ''
        ;
        packages = with pkgs; [
          go_1_22
          # gopls
          oracle-instantclient
          # gotools
          # sqlc
          gomod2nix.packages.${system}.default # gomod2nix CLI
          sbomnix.packages.${system}.default # sbomnix CLI
          # oracle-instantclient
        ];
      };
    });
  };
}
