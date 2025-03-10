# Ensure Fish is in interactive mode before running commands
if status is-interactive
    # Commands to run in interactive sessions can go here
end

# Remove the mapping <C-t> which is used to close the terminal in NeoVim
bind --erase \ct

# Zoxide
if type -q zoxide
    zoxide init fish --cmd cd | source
end

# Starship
starship init fish | source

# Nvim
source ~/.config/nvim.fish

# Astrophysics
source ~/github/my-scripts/astro/astro.fish

# Python
function activate-py-nvim-env
    source ~/.venvs/nvim-env/bin/activate.fish
end

function activate-py-coding-env
    source ~/.venvs/coding-env/bin/activate.fish
end

# Yazi
export EDITOR="nvim"

function y
    set tmp (mktemp -t "yazi-cwd.XXXXXX")
    yazi $argv --cwd-file="$tmp"
    if set cwd (command cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
        builtin cd -- "$cwd"
    end
    rm -f -- "$tmp"
end

# Bundler
if type -q bundle
    set -x GEM_HOME /home/rafi/gems
    set -x PATH $GEM_HOME/bin $PATH
end
