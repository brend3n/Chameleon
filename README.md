# MAC Address Changer

## Overview

The MAC Address Changer is a command-line tool that allows users to change their MAC address on a specified network interface. This tool is useful for scenarios where users need to modify their device's MAC address for privacy, security, or network troubleshooting purposes.

## Features

- Display the current MAC address of a network interface.
- Change the MAC address to a random value.
- Set a specific MAC address provided by the user.
- Save and restore the original MAC address.
- View the history of MAC address changes.

## Prerequisites

- **Operating System:** Linux
- **Permissions:** The tool requires root or superuser permissions to modify network interface settings.

## Usage

There are two ways to use this tool:
1. Command line arguments
2. Menu

## Command Line

```bash
sudo ./mac-changer.sh <interface>
```
### Commands

1. ### **Display Current MAC Address**
    ```bash
    ./mac-changer.sh -d <interface>
    ```
2. ### **Change to Random MAC Address**
    ```bash
    ./mac-changer.sh -r <interface>
    ```
3. ### **Change to Specific MAC Address**
    ```bash
    ./mac-changer.sh -m <new_mac_address> -i <interface>
    ```
4. ### **Restore Original MAC Address**
    ```bash
    ./mac-changer.sh -o <interface>
    ```
5. ### **Display MAC Address Change History**
    ```bash
    ./mac-changer.sh -h
    ```
## Menu Mode

```bash
sudo ./mac-changer.sh <interface>
```

Replace \<interface> with the actual network interface you want to modify.

### Menu Options
1. **Display  current MAC address:** 
    - Shows the current MAC address of the specified network interface.
2. **Change to random MAC address:**
    - Sets a random MAC address for the specified network interface.
3. **Change to specific MAC address:** 
    - Allows the user to enter a specific MAC address for the network interface.
4. **Restore original MAC address:** 
    - Restores the original MAC address for the specified network interface.
5. **Display MAC address change history:** 
    - Shows the history of MAC address changes.
6. **Exit:** 
    -   Exits the script.

## Example
```bash
sudo ./mac-changer.sh eth0
```

## License
This tool is distributed under the MIT License.

## Disclaimer

Changing your MAC address may affect your network connectivity. Use this tool responsibly and ensure compliance with applicable laws and regulations.
