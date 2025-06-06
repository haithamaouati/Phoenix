#!/bin/bash

# Author: Haitham Aouati
# GitHub: github.com/haithamaouati

# Colors
nc="\e[0m"
bold="\e[1m"
underline="\e[4m"
bold_red="\e[1;31m"
bold_green="\e[1;32m"
bold_yellow="\e[1;33m"

# Help message
print_help() {
    clear
    cat <<EOF
Usage: $0 [options]

Options:
  -c, --celsius        Show temperature in Celsius (default if no option)
  -f, --fahrenheit     Show temperature in Fahrenheit
  -c -f                Show both Celsius and Fahrenheit
  -h, --help           Show this help message

Temperature ranges:
  Optimal : 0°C - 35°C (32°F - 95°F)
  Warning : 36°C - 45°C (97°F - 113°F)
  Danger  : 46°C+ (115°F+)
EOF
    exit 0
}

# Dependency check
check_dependencies() {
    for cmd in termux-battery-status jq bc; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            echo "Error: '$cmd' is not installed. Install it with:"
            echo "  pkg install $cmd"
            exit 1
        fi
    done
}

# Defaults
show_celsius=false
show_fahrenheit=false

# Parse arguments
if [[ $# -eq 0 ]]; then
    show_celsius=true
else
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -c|--celsius)
                show_celsius=true
                ;;
            -f|--fahrenheit)
                show_fahrenheit=true
                ;;
            -h|--help)
                print_help
                ;;
            *)
                echo "Unknown option: $1"
                print_help
                ;;
        esac
        shift
    done
fi

# Run checks
check_dependencies

# Clear the screen
clear

# Author info
echo -e "${bold_red}"
cat << "EOF"
   _/|       |\_
  /  |       |  \
 |    \     /    |
 |  \ /     \ /  |
 | \  |     |  / |
 | \ _\_/^\_/_ / |
 |    --\//--    |
  \_  \     /  _/
    \__  |  __/
       \ _ /
      _/   \_   Phoenix
     / _/|\_ \
      /  |  \
       / v \
EOF
echo -e "${nc}"
echo -e " Author: Haitham Aouati"
echo -e " GitHub: ${underline}github.com/haithamaouati${nc}"

# Fetch temperature
temp_c=$(termux-battery-status | jq -r '.temperature')

# Validate
if ! [[ "$temp_c" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    echo "Error: Invalid temperature value: $temp_c"
    exit 1
fi

# Convert to Fahrenheit
temp_f=$(echo "scale=2; ($temp_c * 9 / 5) + 32" | bc)

# Get status and color
get_status() {
    local temp="$1"
    if (( $(echo "$temp < 36" | bc -l) )); then
        echo "Normal|${bold_green}"
    elif (( $(echo "$temp < 46" | bc -l) )); then
        echo "Hot|${bold_yellow}"
    else
        echo "Very hot|${bold_red}"
    fi
}

status_info=$(get_status "$temp_c")
status_label="${status_info%%|*}"
color="${status_info##*|}"

# Optional toast
if [[ "$status_label" == "Very hot" ]]; then
    termux-toast -b white -c red "🔥 CPU Temperature Danger Zone!"
fi

# Output
output=""
if [[ "$show_celsius" == true ]]; then
    output+="Celsius: ${temp_c}°C (${status_label})"
fi

if [[ "$show_fahrenheit" == true ]]; then
    [[ -n "$output" ]] && output+=" | "
    output+="Fahrenheit: ${temp_f}°F (${status_label})"
fi

# Print results
echo -e "\n${color}${output}${nc}\n"
echo -e "${bold}Temperature ranges:${nc}"
echo -e "${bold_green}  Optimal${nc} : 0°C - 35°C (32°F - 95°F)"
echo -e "${bold_yellow}  Warning${nc} : 36°C - 45°C (97°F - 113°F)"
echo -e "${bold_red}  Danger${nc}  : 46°C+ (115°F+)\n"
