set -g fish_greeting

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

    # Direnv + Zoxide
    command -v direnv &> /dev/null && direnv hook fish | source
    command -v zoxide &> /dev/null && zoxide init fish | source

    # Better ls
    alias ls='eza --icons --group-directories-first -1'

    # Abbrs
    abbr py 'python3'
    abbr lg 'lazygit'
    abbr gd 'git diff'
    abbr ga 'git add .'
    abbr gc 'git commit -am'
    abbr gl 'git log'
    abbr gs 'git status'
    abbr gst 'git stash'
    abbr gsp 'git stash pop'
    abbr gp 'git push'
    abbr gpl 'git pull'
    abbr gsw 'git switch'
    abbr gsm 'git switch main'
    abbr gb 'git branch'
    abbr gbd 'git branch -d'
    abbr gco 'git checkout'
    abbr gsh 'git show'

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

# pnpm
set -gx PNPM_HOME "/home/abyssal/.local/share/pnpm"
if not string match -q -- $PNPM_HOME $PATH
  set -gx PATH "$PNPM_HOME" $PATH
end
# pnpm end

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH
