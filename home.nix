# home.nix
# home-manager switch

{ config, pkgs, ... };

{
    home.username = "noctuacode";
    home.homeDirectory = "/Users/noctuacode";
    home.stateVersion = "24.05";

    home.packages = [
    ];

    home.file = {
        ".zshrc".source = ~/dotfiles/zshrc/.zshrc;
        ".config/wezterm".source = ~/dotfiles/wezterm;
        ".config/skhd".source = ~/dotfiles/skhd;
        ".config/starship".source = ~/dotfiles/starship;
        ".config/zellij".source = ~/dotfiles/zellij;
        ".config/nvim".source = ~/dotfiles/nvim;
        # ".config/nix".source = ~/dotfiles/nix;
        # ".config/nix-darwin".source = ~/dotfiles/nix-darwin;
        ".config/tmux".source = ~/dotfiles/tmux;
        ".config/ghostty".source = ~/dotfiles/ghostty;
    };

    home.sessionVariables = {
    };

    home.sessionPath = [
        "/run/current-system/sw/bin"
        "$HOME/.nix-profile/bin"
    ];
    programs.home-manager.enable = true;
    programs.zsh = {
        enable = true;
        initExtra = ''
        # Add any additional configurations here
        export PATH=/run/current-system/sw/bin:$HOME/.nix-profile/bin:$PATH
        if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
            . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
        fi
        '';
    };
};
