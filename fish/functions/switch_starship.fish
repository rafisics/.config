function switch_starship
    set config_dir "$HOME/.config/starship"
    set dest "$HOME/.config/starship.toml"

    if test (count $argv) -eq 0
        echo "Usage: switch_starship <number>"
        echo "Available configs:"
        ls $config_dir | grep -oE 'starship_[0-9]+' | sort -V
        return 1
    end

    set target_config "$config_dir/starship_$argv[1].toml"

    if test -f $target_config
        cp $target_config $dest
        echo "Switched Starship config to starship_$argv[1]"
        starship init fish | source  # Reload Starship
    else
        echo "Config 'starship_$argv[1]' not found. Available configs:"
        ls $config_dir | grep -oE 'starship_[0-9]+' | sort -V
    end
end
