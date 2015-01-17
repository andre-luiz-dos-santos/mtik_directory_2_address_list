# Directory to Address List

The program __mtik_directory_2_address_list__ allows any process,
 with write permission to a directory,
 to add and remove entries from a Mikrotik IP Firewall Address List,
 without having the process connect to the Mikrotik device directly.

For example, the symbolic link

    1.2.3.4 -> down_20

would be created on the Mikrotik device like

    /ip firewall address-list add address=1.2.3.4 list=<prefix>_down_20

Likewise, deleting the symbolic link would also delete the address list entry.

## Installation

    gem install mtik_directory_2_address_list
