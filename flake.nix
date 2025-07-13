{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    crane.url = "github:ipetkov/crane";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, crane, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        craneLib = crane.mkLib pkgs;
      in
    {
      packages.default = craneLib.buildPackage {
        src = craneLib.cleanCargoSource ./.;

        # Add extra inputs here or any other derivation settings
        # doCheck = true;
        # buildInputs = [];
        # nativeBuildInputs = [];
      };
    }) // {
      nixosModules.default = {config, lib, pkgs, ...}:
        with lib;
        let 
          appPackage = self.packages.${pkgs.system}.default;
          cfg = config.services.pdf_diff_gen;
        in {
          options.services.pdf_diff_gen = {
            enable = mkEnableOption "Enable pdf_diff_gen serive";
            
            config = mkOption {
              type = types.attrs;
              description = "Config for pdf_diff_gen";
              default = {};
            };
          };

        config = mkIf cfg.enable {
          systemd.services.pdf_diff_gen = {
            description = "pdf_diff_gen service";
            wantedBy = ["multi-user.target"];
            after = ["network.target"];
            serviceConfig = {
              ExecStart = "${appPackage}/bin/pdf_diff_gen ${cfg.config.current} ${cfg.config.last} ${cfg.config.diff} ${cfg.config.pdfium} ${cfg.config.interval}";
              Restart = "always";
              WorkingDirectory = appPackage;
            };

          };
        };
     };

   };
}
