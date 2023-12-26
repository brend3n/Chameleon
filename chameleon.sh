#!/bin/bash

# Configuration file to store MAC address history
CONFIG_FILE="./.macchanger_history"

# File to store the original MAC address in write-only mode
OG_MAC_FILE="./.original_mac_write_only"

# File to store the original MAC address and flag
OG_MAC_FILE_FLAG="./.original_mac_write_once.flag"

# Assign the provided interface to a variable
interface=$1

display_help() {
    echo "Usage: $0 <options>"
    echo "Options:"
    echo "  -d <interface>        Display current MAC address"
    echo "  -r <interface>        Change to random MAC address"
    echo "  -m <new_mac_address> -i <interface>  Change to specific MAC address"
    echo "  -o <interface>        Restore original MAC address"
    echo "  -p                    Display history"
    echo "  -h                    Display this help message"
}

# Function to display the current MAC address
display_current_mac() {
    current_mac=$(ifconfig $interface | awk '/ether/ {print $2}')
    echo "Current MAC address for $interface: $current_mac"
}

# Function to change the MAC address to a specific value
change_to_specific_mac() {
    # Read user input for the new MAC address
    read -p "Enter the new MAC address: " new_mac

    # Validate the entered MAC address format
    if [[ ! $new_mac =~ ^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$ ]]; then
        echo "Invalid MAC address format. Please enter a valid address."
        return
    fi

    # Disable the network interface
    ifconfig $interface down

    # Change the MAC address
    ifconfig $interface hw ether $new_mac

    # Enable the network interface
    ifconfig $interface up

    # Display the new MAC address
    echo "Changed MAC address of $interface to $new_mac"

    # Save the new MAC address to the history file
    echo "$(date) $new_mac" >> $CONFIG_FILE
}

# Function to save the original MAC address to a file writable only once
save_original_mac() {
    # Check if the flag file exists
    if [ -e "$OG_MAC_FILE_FLAG" ]; then
        echo "Original MAC address saved."
        return
    fi

    # Read the original MAC address from the system
    original_mac=$(ifconfig $interface | awk '/ether/ {print $2}')

    # Save the original MAC address to the file
    echo "$original_mac" > $OG_MAC_FILE
    touch $OG_MAC_FILE_FLAG

    # Display a confirmation message
    echo "Original MAC address <${original_mac}> saved to $OG_MAC_FILE (write-only)."

    # Set permissions to make the file writable only once
    chmod a-w "$OG_MAC_FILE"
}

# Function to restore the original MAC address
restore_original_mac() {
    # Read the original MAC address from the write-only file
    original_mac=$(cat $OG_MAC_FILE 2>/dev/null)

    # Check if the write-only file exists and contains a MAC address
    if [ -z "$original_mac" ]; then
        echo "Original MAC address not found. Please save it first using option 4."
        return
    fi

    # Disable the network interface
    ifconfig $interface down

    # Change the MAC address back to the original
    ifconfig $interface hw ether $original_mac

    # Enable the network interface
    ifconfig $interface up

    # Display the restored MAC address
    echo "Restored original MAC address for $interface: $original_mac"
}

# Function to display MAC address history
display_mac_history() {
    echo "MAC address change history:"
    cat $CONFIG_FILE
}

# Function to change the MAC address
change_to_random_mac() {
    # Generate a random MAC address
    # new_mac=$(printf '00:1D:%02X:%02X:%02X:%02X\n' $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)))
    new_mac=$(printf '%02X:%02X:%02X:%02X:%02X:%02X\n' $(( 2*(RANDOM%128) + 2 )) $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)))

    # Disable the network interface
    ifconfig $interface down

    # Change the MAC address
    ifconfig $interface hw ether $new_mac

    # Enable the network interface
    ifconfig $interface up

    # Display the new MAC address
    echo "Changed MAC address of $interface to $new_mac"

    # Save the new MAC address to the history file
    echo "$(date) $new_mac" >> $CONFIG_FILE
}

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root."
    echo "Usage: sudo $0 <interface>"
    exit 1
fi

# Check if the configuration file exists, create it if not
if [ ! -e "$CONFIG_FILE" ]; then
    touch "$CONFIG_FILE"
fi

# Check if the network interface is provided as an argument
if [ -z "$1" ]; then
    echo "Usage: sudo $0 <interface>"
    exit 1
fi


# Save the original MAC address if its the first time running the script
save_original_mac

do_menu_mode() {
    # Infinite loop
    while true; do
        # Display the menu
        echo "1. Display current MAC address"
        echo "2. Change to random MAC address"
        echo "3. Change to a specific MAC address"
        echo "4. Restore original MAC address"
        echo "5. Display MAC address change history"
        echo "6. Exit"

        # Read user choice
        read -p "Enter your choice (1-6): " choice

        echo -e "\n\n"
        # Perform the selected action
        case $choice in
            1) display_current_mac ;;
            2) change_to_random_mac ;;
            3) change_to_specific_mac ;;
            4) restore_original_mac ;;
            5) display_mac_history ;;
            6) exit 0 ;;
            *) echo "Invalid choice. Please try again." ;;
        esac
        echo -e "\n\n"
    done   
}


while getopts ":d:hpr:o:m:i:" opt; do
    case $opt in
        d)
            flag_d=true
            interface="$OPTARG"
            ;;
        h)
            flag_h=true
            ;;
        p)
            flag_p=true          
            ;;
        r)
            flag_r=true
            interface="$OPTARG"
            ;;
        m)
            flag_m=true
            new_mac_addr="$OPTARG"
            ;;
        o)
            flag_o=true
            interface="$OPTARG"
            ;;
        i)
            flag_i=true
            interface="$OPTARG"
            ;;
        \?)
            echo "Invalid option: -$OPTARG"
            display_help
            exit 1
            ;;
        :)
            echo "Option -$OPTARG requires an argument."
            display_help
            exit 1
            ;;
    esac    
done

# Else, no options so we doin menu mode
if [ "$flag_d" = true ] || \
   [ "$flag_h" = true ] || \
   [ "$flag_p" = true ] || \
   [ "$flag_r" = true ] || \
   [ "$flag_m" = true ] || \
   [ "$flag_o" = true ] || \
   [ "$flag_i" = true ]; then
    : # no-op
else
    echo -e "Menu mode"
    do_menu_mode
fi

if [ "$flag_d" = true ]; then
    display_current_mac
elif [ "$flag_r" = true ]; then
    change_to_random_mac
elif [ "$flag_o" = true ]; then
    restore_original_mac
elif [ "$flag_p" = true ]; then
    display_mac_history
elif [ "$flag_h" = true ]; then
    display_help
elif [ "$flag_m" = true ]; then
    if [ "$flag_i" = true ]; then
        change_to_specific_mac
    else
        echo -e "Missing arg for interface"
    fi 
else
    echo -e "Invalid command"
    display_help
    exit 1
fi
