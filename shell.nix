{ pkgs ? import <nixpkgs> {
    config.allowUnfree = true;
} }:

pkgs.mkShell {
    name = "efc-poetry";
    
    buildInputs = with pkgs; [ 
        python310Packages.poetry
    ];

    shellHook = ''
      export LD_LIBRARY_PATH=${pkgs.libGL}/lib:${pkgs.libGLU}/lib:${pkgs.freeglut}/lib:${pkgs.xorg.libX11}/lib:${pkgs.stdenv.cc.cc.lib}/lib:${pkgs.cudaPackages_10_1.cudatoolkit}/lib:${pkgs.cudaPackages_10_1.cudnn}/lib:${pkgs.cudaPackages_10_1.cudatoolkit.lib}/lib:$LD_LIBRARY_PATH
    '';

}
