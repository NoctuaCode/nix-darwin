{
  description = "Noctua Darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew, home-manager }:
  let
    configuration = { pkgs, config, ... }: {
      nixpkgs.config.allowUnfree = true;

      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment = {
        systemPackages =
        [
          pkgs.bat
          pkgs.bottom
          pkgs.btop
          pkgs.direnv
          pkgs.dfu-util
          pkgs.eza
          pkgs.fd
          pkgs.fish
          pkgs.fzf
          pkgs.gcc-arm-embedded
          pkgs.go
          pkgs.gum
          pkgs.lazygit
          pkgs.luarocks
          pkgs.mercurial
          pkgs.mkalias
          pkgs.neovim
          pkgs.nodejs_22
          pkgs.pam-reattach
          pkgs.postgresql_16
          pkgs.python3
          pkgs.qmk
          pkgs.ripgrep
          pkgs.sesh
          pkgs.stow
          pkgs.starship
          pkgs.tmux
          pkgs.yazi
          pkgs.zig
          pkgs.zoxide
        ];
        etc."pam.d/sudo_local".text = ''
          # Manage by Nix Darwin
          auth optional ${pkgs.pam-reattach}/lib/pam/pam_reattach.so ignore_ssh
          auth sufficient pam_tid.so
        '';
      };

      homebrew = {
        enable = true;
        brews = [
          "mas"
        ];
        taps = [
          "nikitabobko/tap"
        ];
        casks = [
          "1password"
          "aerospace"
          "arc"
          "betterdisplay"
          "cleanmymac"
          "dbngin"
          "dbeaver-community"
          "firefox"
          "google-chrome"
          "herd"
          "hoppscotch"
          "karabiner-elements"
          "keymapp"
          "kitty"
          "messenger"
          "miniconda"
          "nordvpn"
          "raycast"
          "signal"
          "sony-ps-remote-play"
          "shottr"
          "visual-studio-code"
          "warp"
          "wezterm"
        ];
        masApps = {
        };
        onActivation = {
          autoUpdate = true;
          cleanup = "zap";
          upgrade = true;
        };
      };

      fonts.packages = with pkgs; [
        fira-code
        (pkgs.nerdfonts.override { fonts = [ "JetBrainsMono" "FiraCode" ]; })
      ];

      system.activationScripts.applications.text = let
        env = pkgs.buildEnv {
          name = "system-applications";
          paths = config.environment.systemPackages;
          pathsToLink = "/Applications";
        };
      in
        pkgs.lib.mkForce ''
          # Set up applications.
          echo "setting up /Applications..." >&2
          rm -rf /Applications/Nix\ Apps
          mkdir -p /Applications/Nix\ Apps
          find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
          while read src; do
            app_name=$(basename "$src")
            echo "copying $src" >&2
            ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
          done
        '';

      system = {
        defaults = {
          finder = {
            FXPreferredViewStyle = "clmv";
            AppleShowAllExtensions = true;
            AppleShowAllFiles = true;
            CreateDesktop = false;
            ShowPathbar = true;
            ShowStatusBar = true;
          };
          dock = {
            appswitcher-all-displays = true;
            autohide = true;
            autohide-delay = 0.10;
            launchanim = false;
            magnification = false;
            mineffect = "suck";
            showhidden = true;
            show-process-indicators = false;
            static-only = true;
            wvous-br-corner = 5;
            wvous-tr-corner = 13;
          };
          loginwindow.GuestEnabled  = false;
          NSGlobalDomain.AppleICUForce24HourTime = true;
          NSGlobalDomain.AppleInterfaceStyle = "Dark";
          NSGlobalDomain.KeyRepeat = 2;
          NSGlobalDomain."com.apple.keyboard.fnState" = true;
        };
      };
      security.pam.enableSudoTouchIdAuth = true;

      # Auto upgrade nix package and the daemon service.
      services.nix-daemon.enable = true;
      # nix.package = pkgs.nix;

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Create /etc/zshrc that loads the nix-darwin environment.
      programs.zsh.enable = true;  # default shell on catalina
      # programs.fish.enable = true;

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 5;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";

      users.users.noctuacode.home = "/Users/noctuacode";
      home-manager.backupFileExtension = "backup";
      nix.configureBuildUsers = true;
      nix.useDaemon = true;
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#NoctuaCodes-MacBook-Air
    darwinConfigurations."NoctuaCodes-MacBook-Air" = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [
        configuration
        nix-homebrew.darwinModules.nix-homebrew
        {
          nix-homebrew = {
            enable = true;
            enableRosetta = true;
            user = "noctuacode";
            autoMigrate = true;
          };
        }
        home-manager.darwinModules.home-manager
        {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            #home-manager.users.noctuacode = import ./home.nix;

            # Optionally, use home-manager.extraSpecialArgs to pass
            # arguments to home.nix
          }
      ];
    };

    # Expose the package set, including overlays, for convenience.
    darwinPackages = self.darwinConfigurations."NoctuaCodes-MacBook-Air".pkgs;
  };
}
