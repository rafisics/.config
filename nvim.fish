# Command to upgrade Neovim stable version
function upgrade_nvim
    # Save the current directory
    set original_dir (pwd)

    # Navigate to the Neovim source directory
    echo "Navigating to Neovim source directory..."
    cd ~/neovim || begin
        echo "Error: Neovim directory not found!"
        return 1
    end

    # Fetch the latest changes from the remote repository
    echo "Fetching latest changes from the Neovim repository..."
    git fetch origin

    # Checkout the stable branch
    echo "Checking out the stable branch..."
    git checkout stable

    # Pull the latest stable updates
    echo "Pulling latest stable updates..."
    git pull origin stable

    # Build Neovim
    echo "Building Neovim with CMAKE_BUILD_TYPE=RelWithDebInfo..."
    make CMAKE_BUILD_TYPE=RelWithDebInfo

    # Install the new build
    echo "Installing the new build of Neovim..."
    sudo make install

    # Return to the original directory
    cd $original_dir
    echo "Returned to the original directory: $original_dir"

    # Verify the new version
    echo "Neovim upgrade completed. Verifying version..."
    nvim --version
end

# Command to delete nvim local cache
function delete_nvim_local_cache
    rm -rf ~/.local/share/nvim
    rm -rf ~/.local/state/nvim
    rm -rf ~/.cache/nvim
end

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

# Command to toggle between NeoTeX and NvChad
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