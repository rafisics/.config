if status is-interactive
    # Commands to run in interactive sessions can go here
end

bind --erase \ct
# removes the mapping <C-t> which is being used to close the terminal in NeoVim

if type -q zoxide
zoxide init fish --cmd cd | source
# removes the mapping <C-t> which is being used to close the terminal in NeoVim
end

# enables starship config 
starship init fish | source

# Commands to switch from NeoTeX to NvChad
function switch_to_nvchad
    # Back up NeoTeX
    mv ~/.config/nvim{,.bak}
    mv ~/.local/share/nvim{,.bak}
    mv ~/.local/state/nvim{,.bak}
    mv ~/.cache/nvim{,.bak}

    # Move to NvChad
    mv ~/.config/nvim{.chad,}
    mv ~/.local/share/nvim{.chad,}
    mv ~/.local/state/nvim{.chad,}
    mv ~/.cache/nvim{.chad,}
end

# Commmands to switch from NvChad to NeoTeX
function switch_to_neotex
    # Back up NvChad
    mv ~/.config/nvim{,.chad}
    mv ~/.local/share/nvim{,.chad}
    mv ~/.local/state/nvim{,.chad}
    mv ~/.cache/nvim{,.chad}

    # Move to NeoTeX
    mv ~/.config/nvim{.bak,}
    mv ~/.local/share/nvim{.bak,}
    mv ~/.local/state/nvim{.bak,}
    mv ~/.cache/nvim{.bak,}
end

# Toggle between NeoTeX and NvChad
function toggle_nvim
    if test -e ~/.config/nvim.chad -a ! -e ~/.config/nvim.bak
        # Switch from NeoTeX to NvChad
        switch_to_nvchad
    else if test -e ~/.config/nvim.bak -a ! -e ~/.config/nvim.chad
        # Switch from NvChad to NeoTeX
        switch_to_neotex
    else
        echo "Error: Unable to determine current nvim configuration."
        return 1
    end
    nvim
end
