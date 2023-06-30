{ optionalString, ... }:

{
  moduleCopyCommands =
    { fetchFromGitHub }:
    { path, repo, rev, sha256, /* createDotGit, owner, */ ... }@module:
    let
      source = fetchFromGitHub {
        owner = module.owner or "zephyrproject-rtos";
        inherit repo rev sha256;
      };
      copyCommands = /* bash */ ''
        mkdir -p $(dirname ${path})
        cp --no-preserve=mode -r ${source} ${path}
      '';
      # west requires a .git dir for some modules
      createDotGit = module.createDotGit or false;
      createDotGitCommands = optionalString createDotGit /* bash */ ''
        git -C ${path} init
        git -C ${path} config user.email "nix-builder@example.com"
        git -C ${path} config user.name "Nix Builder"
        git -C ${path} add -A
        git -C ${path} commit -m "nix-build"
        git -C ${path} checkout -b manifest-rev
        git -C ${path} checkout --detach manifest-rev
      '';
    in
    copyCommands + createDotGitCommands;
}
