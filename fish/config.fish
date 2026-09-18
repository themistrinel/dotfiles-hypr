set -g fish_greeting

# Garante que ~/.local/bin tem prioridade (antes de /usr/sbin etc.)
fish_add_path --prepend --global ~/.local/bin

if status is-interactive
    # Auto-start zellij se não estiver dentro dele já e não for terminal de IDE
    # if not set -q ZELLIJ
    #     and not set -q VSCODE_INJECTION
    #     and not set -q KIRO_TERMINAL
    #     and test "$TERM_PROGRAM" != "vscode"
    #     zellij
    # end

    # Starship custom prompt
    starship init fish | source

    # Rust/Cargo
    test -f ~/.cargo/env.fish && source ~/.cargo/env.fish

    # Direnv + Zoxide
    command -v direnv &> /dev/null && direnv hook fish | source
    command -v zoxide &> /dev/null && zoxide init fish --cmd cd | source

    # Better ls (eza) + Better cat (bat)
    alias ls='eza --icons --group-directories-first -1'
    alias cat='bat --paging=never'

    # GTK color scheme (sem trocar wallpaper/pywal)
    alias dark='gtk-color dark'
    alias light='gtk-color light'
    alias toggle-theme='gtk-color toggle'

    # Abbrs
    abbr py 'python3'
    abbr lg 'lazygit'
    # ga/gd/gco/gsw/gbd now come from forgit (fzf pickers)
    abbr gc 'git commit -am'
    abbr gl 'git log'
    abbr gs 'git status'
    abbr gst 'git stash'
    abbr gsp 'git stash pop'
    abbr gp 'git push'
    abbr gpl 'git pull'
    abbr gsm 'git switch main'
    abbr gb 'git branch'
    abbr gsh 'git show'

    # forgit: fzf-powered interactive git (ga/gd/glo/gco/gsw/gbd/gclean...)
    set forgit_stash_push gstp  # avoid clashing with the gsp (stash pop) abbr
    set -x FORGIT_COPY_CMD wl-copy  # Wayland clipboard for ctrl-y
    test -f ~/.forgit/conf.d/forgit.plugin.fish; and source ~/.forgit/conf.d/forgit.plugin.fish

    abbr l 'ls'
    abbr ll 'ls -l'
    abbr la 'ls -a'
    abbr lla 'ls -la'
    abbr anti 'antigravity'
    abbr ag 'antigravity'

    # Custom colours
    set -g fish_color_autosuggestion 'brblack'
    set -g fish_color_command 'magenta'
    set -g fish_color_param 'blue'
    set -g fish_color_normal 'normal'

    # For jumping between prompts in foot terminal
    function mark_prompt_start --on-event fish_prompt
        echo -en "\e]133;A\e\\"
    end
end


# Added by LM Studio CLI tool (lms)
set -gx PATH $PATH /home/abyssal/.lmstudio/bin

# Secrets (API keys) — arquivo separado, não commitar
source ~/.config/fish/secrets.fish

# pnpm
set -gx PNPM_HOME "/home/abyssal/.local/share/pnpm"
if not string match -q -- $PNPM_HOME $PATH
  set -gx PATH "$PNPM_HOME" $PATH
end
# pnpm end

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH


# SSH agent persistente via keychain
# if status is-login
#     keychain --quiet --nogui ~/.ssh/id_ed25519_gitlab
# end
# if test -f ~/.keychain/(uname -n)-fish
#     source ~/.keychain/(uname -n)-fish
# end
echo -e '\e[5 q'  # bar cursor

# pyenv
set -gx PYENV_ROOT "$HOME/.pyenv"
fish_add_path "$PYENV_ROOT/bin"
pyenv init - fish | source
# opencode
fish_add_path /home/abyssal/.opencode/bin

# open-design: aponta para o vela CI/CD como fallback
set -gx OPEN_DESIGN_VELA_CLI_BIN (command -s vela 2>/dev/null; or echo "")
# npm-global: usa fish_add_path em vez de set -Ux (evita commit universal lento na inicialização)
fish_add_path --prepend --global $HOME/.npm-global/bin
