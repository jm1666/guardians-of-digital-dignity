#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo -e "\e[1;31m[!] ERROR: This script must be run with sudo.\e[0m" 
   exit 1
fi

MODE=$1
ETH="eth0"
WLAN_WAN="wlan1"
EXIT_NODE=$2
MODE_FILE="/var/lib/fortress_mode"

case $MODE in
  maint)
    echo -e "\e[1;34m[-] Switching to Maintenance MODE...\e[0m"
    # eth0 becomes your trusted management port
    firewall-cmd --zone=trusted --change-interface=$ETH
    # Open all routing paths
    firewall-cmd --permanent --policy hotspotToPublic --set-target ACCEPT
    firewall-cmd --policy hotspotToVPN --set-target ACCEPT
    # Kill the tunnel for raw speed
    tailscale up --exit-node=
    echo -e "\e[1;33m[!] WARNING: Changes are RUNTIME ONLY. Reboot will Seal the Fortress.\e[0m"
    ;;

  lean)
    echo -e "\e[1;33m[|] Switching to LEAN MODE (Scout/DNS Only)...\e[0m"
    # eth0/wlan1 are Public WAN (Hardened DROP)
    firewall-cmd --permanent --zone=public --change-interface=$ETH
    firewall-cmd --permanent --zone=public --change-interface=$WLAN_WAN
    # Block Forwarding (DNS Hijack only)
    firewall-cmd --permanent --policy hotspotToPublic --set-target ACCEPT
    firewall-cmd --permanent --policy hotspotToVPN --set-target REJECT
    tailscale up --reset --accept-routes=true || exit 1
    firewall-cmd --reload
    echo "LEAN" > "$MODE_FILE"
    echo -e "\e[1;32m[✓] Lean Mode: eth0/wlan1 are DROP. Forwarding REJECTED.\e[0m"
    ;;

  secure)
    echo -e "\e[1;31m[!] Switching to SECURE MODE (VPN)...\e[0m"
    # Harden all external interfaces
    firewall-cmd --permanent --zone=public --change-interface=$ETH
    firewall-cmd --permanent --zone=public --change-interface=$WLAN_WAN
    # Kill-switch: All traffic MUST hit the VPN
    firewall-cmd --permanent --policy hotspotToPublic --set-target REJECT
    firewall-cmd --permanent --policy hotspotToVPN --set-target ACCEPT
    # Force Tailscale Exit Node
    tailscale up --reset --exit-node=$2 --exit-node-allow-lan-access=true --accept-routes=true || exit 1
    firewall-cmd --reload
    echo "SECURE" > "$MODE_FILE"
    echo -e "\e[1;32m[✓] Secure Mode: Tunneling through $EXIT_NODE.\e[0m"
    ;;

  *)
    echo "Usage: sudo fortress-mode [maint|lean|secure]"
    ;;
esac
