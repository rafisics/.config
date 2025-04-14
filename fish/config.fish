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

# Default editor 
export EDITOR="nvim"

# Bundler
if type -q bundle
    set -x GEM_HOME /home/rafi/gems
    set -x PATH $GEM_HOME/bin $PATH
end
