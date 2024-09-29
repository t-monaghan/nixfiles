if set -q argv[2]
    git clone https://github.com/cultureamp/"$argv[1]" "$argv[2..-1]"
else
    git clone https://github.com/cultureamp/"$argv[1]"
    cd "$argv[1]"
end
