# My Mac Development Setup

This repository contains scripts and configuration files for setting up a development environment on macOS. The setup includes various tools, package managers, and configurations to enhance productivity and streamline the development workflow.

## Setup Script

The `setup_my_mac.sh` script automates the installation and configuration of various tools and utilities. Here's an overview of what it does:

1. Installs and updates Homebrew
2. Installs essential packages and tools
3. Sets up fonts (JetBrains Mono Nerd Font and Symbols Only Nerd Font)
4. Configures Fish shell as the default shell
5. Installs Fisher (plugin manager for Fish)
6. Sets up Node Version Manager (NVM) and installs the latest LTS version of Node.js
7. Installs global npm packages using Bun
8. Creates and configures `.profile`, `config.fish`, `.czrc`, and `init.vim` files

To run the setup script:

```bash
./setup_my_mac.sh
```

## Fish Shell Configuration

The Fish shell is configured with various aliases, path settings, and integrations. Key features include:

- Custom greeting (disabled)
- Aliases for common commands and navigation
- Path configurations for Homebrew, local binaries, and Node.js
- Integration with Oh My Posh for a customized prompt
- VSCode and Cursor shell integration
- Custom `git` function to use Commitizen for commits

For more details, see the `config.fish` file

## Profile Configuration

The `.profile` file is set up with environment variables for Homebrew, NVM, and npm. It ensures that these tools are properly loaded and configured in the shell environment.

## Installed Tools and Utilities

The setup includes various tools and utilities to enhance the development experience:

- Homebrew (package manager)
- Git, Vim, Neovim
- Fish shell with Oh My Posh
- Bun (JavaScript runtime and toolkit)
- Bat (alternative to `cat`)
- Eza (modern replacement for `ls`)
- Node.js (via NVM)
- Global npm packages: eslint, prettier, ngrok, npm-check-updates, pm2, typescript, commitizen, cz-conventional-changelog, nx

## Fonts

The setup installs JetBrains Mono Nerd Font and Symbols Only Nerd Font, which are optimized for development environments and terminal use.

## Neovim Configuration

A basic Neovim configuration is provided in the `init.vim` file, which includes settings for:

- File searching and encoding
- Line numbers and indentation
- Performance optimizations
- Search behavior
- Folding
- Clipboard integration
- Mouse support
- Transparent background

## Commitizen Configuration

The `.czrc` file is set up to use the `cz-conventional-changelog` adapter for Commitizen, ensuring consistent commit messages.

## Customization

Feel free to modify the `setup_my_mac.sh`, `config.fish`, `.profile`, `init.vim`, or `.czrc` files to suit your specific needs. You can add or remove packages, change aliases, or adjust environment variables as needed.

## Maintenance

To keep your system up-to-date, you can use the `upsys` alias, which updates Homebrew packages and global npm packages:

```fish
upsys
```

This alias runs the following commands:
- `brew update && brew upgrade && brew cleanup && brew doctor`
- `bun -g update`

Enjoy your new development environment!
