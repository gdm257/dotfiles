# Add your reusable home-manager modules to this directory, on their own file (https://nixos.wiki/wiki/Module).
# These should be stuff you would like to share with others, not your personal configurations.
{
  # List your module files here
  # my-module = import ./my-module.nix;
  # access from outputs.homeManagerModules.my-module

  # ==== DevOps ====
  bash = import ./bash.nix;
  cpp = import ./cpp.nix;
  csharp = import ./csharp.nix;
  go = import ./go.nix;
  haskell = import ./haskell.nix;
  java = import ./java.nix;
  javascript = import ./javascript.nix;
  lua = import ./lua.nix;
  nix = import ./nix.nix;
  python = import ./python.nix;
  rust = import ./rust.nix;
  binary = import ./binary.nix;
  vim = import ./vim.nix;
  vscode = import ./vscode.nix;
}
