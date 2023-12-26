#!/bin/bash

# Configuration file to store MAC address history
CONFIG_FILE="./.macchanger_history"

# JSON file to store original MAC addresses for different interfaces
JSON_FILE="./.original_mac_addresses.json"

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
    echo "  -s                    Show network interfaces"
    echo "  -h                    Display this help message"
}

get_network_interfaces() {
    ifconfig -s | awk '{print $1}' | tail -n +2
}

show_network_interfaces () {
    echo "Network Interfaces"
    interface_count=1
    for if in $(get_network_interfaces); do
        echo "$interface_count: $if"
        interface_count=$(($interface_count + 1))
    done
}

# Function to display the current MAC address
display_current_mac() {
    current_mac=$(ifconfig $interface | awk '/ether/ {print $2}')
    echo "Current MAC address for $interface: $current_mac"
}

# Function to change the MAC address to a specific value
change_to_specific_mac() {
    new_mac=$1

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

# Function to save the original MAC address to the JSON file
save_original_mac_to_json() {
    original_mac=$(ifconfig $interface | awk '/ether/ {print $2}')
    
    # Read existing JSON file
    json_data=""
    local network_interface="null"
    if [ -e "$JSON_FILE" ]; then
        json_data=$(cat $JSON_FILE)
        network_interface=$(jq -r --arg intf "$interface" '.[$intf]' $JSON_FILE)
    fi

    # Does not exist, so write it
    if [ "$network_interface" == "null" ]; then
        # Update JSON data with the new original MAC address
        json_data=$(echo $json_data | jq -n --arg interface "$interface" --arg original_mac "$original_mac" '.[$interface] = $original_mac')
        echo "json_data: $json_data"
        # Write back to the JSON file
        echo $json_data >> $JSON_FILE
    else
        # Already exists so dont update it
        # echo -e "Already exists"
        # echo -e "$network_interface"
        :
    fi

}

# Function to restore the original MAC address
restore_original_mac() {
    # Read the original MAC address from the JSON file
    local original_mac=$(jq -r --arg intf "$interface" '.[$intf]' $JSON_FILE)

    # Check if the JSON file contains the original MAC address for the specified interface
    if [ "$original_mac" == "null" ]; then
        echo "Original MAC address not found in the JSON file for interface $interface."
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
# save_original_mac

do_menu_mode() {
    # Infinite loop
    while true; do
        # Display the menu
        echo "1. Display current MAC address"
        echo "2. Change to random MAC address"
        echo "3. Change to a specific MAC address"
        echo "4. Restore original MAC address"
        echo "5. Display MAC address change history"
        echo "6. Show Network Interfaces"
        echo "7. Exit"

        # Read user choice
        read -p "Enter your choice (1-6): " choice

        echo -e "\n\n"
        # Perform the selected action
        case $choice in
            1) display_current_mac ;;
            2) change_to_random_mac ;;
            3)
                # Read user input for the new MAC address
                read -p "Enter the new MAC address: " new_mac
                change_to_specific_mac $new_mac
                ;;
            4) restore_original_mac ;;
            5) display_mac_history ;;
            6) show_network_interfaces;;
            7) exit 0 ;;
            *) echo "Invalid choice. Please try again." ;;
        esac
        echo -e "\n\n"
    done   
}


while getopts ":hpsd:r:o:m:i:" opt; do
    case $opt in
        d)
            flag_d=true
            interface="$OPTARG"
            # Save the original MAC address if its the first time running the script
            save_original_mac_to_json   
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
            # Save the original MAC address if its the first time running the script
            save_original_mac_to_json
            ;;
        m)
            flag_m=true
            new_mac_addr="$OPTARG"
            ;;
        o)
            flag_o=true
            interface="$OPTARG"
            # Save the original MAC address if its the first time running the script
            save_original_mac_to_json
            ;;
        i)
            flag_i=true
            interface="$OPTARG"
            # Save the original MAC address if its the first time running the script
            save_original_mac_to_json
            ;;
        s)
            flag_s=true            
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
   [ "$flag_s" = true ] || \
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
elif [ "$flag_s" = true ]; then
    show_network_interfaces
elif [ "$flag_m" = true ]; then
    if [ "$flag_i" = true ]; then
        change_to_specific_mac $new_mac_addr
    else
        echo -e "Missing arg for interface"
    fi 
else
    echo -e "Invalid command"
    display_help
    exit 1
fi