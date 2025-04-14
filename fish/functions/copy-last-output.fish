function copy-last-output
    # Get the last command including newlines
    set -l last_cmd (history --max=1 | string collect)

    if test -z "$last_cmd"
        echo "No command found in history."
        return 1
    end

    echo "⏳ Running: $last_cmd"
    set -l tmpfile (mktemp)

    # Run command, capture output, and display it
    set -l cmd_output (eval "$last_cmd" | tee /dev/tty | string collect)

    # Combine command and output
    echo -n "❯ $last_cmd \n $cmd_output" | xclip -selection clipboard
    
    rm $tmpfile
    echo "✅ Command and output copied to clipboard."
end
