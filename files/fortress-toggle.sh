#!/bin/bash
# Fortress Tri-Mode: eth0/wlan1 as WAN, wifi0 as LAN
# Usage: sudo fortress-mode [home|lean|secure]

# 1. ENFORCE ROOT/SUDO
if [[ $EUID -ne 0 ]]; then
   echo -e "\e[1;31m[!] ERROR: This script must be run with sudo.\e[0m" 
   exit 1
fi

MODE=$1
ETH="eth0"
WLAN_WAN="wlan1"
EXIT_NODE=$2

case $MODE in
  home)
    echo -e "\e[1;34m[-] Switching to HOME MODE (Maintenance)...\e[0m"
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
    tailscale up --exit-node=
    firewall-cmd --reload
    echo -e "\e[1;32m[✓] Lean Mode: eth0/wlan1 are DROP. Forwarding REJECTED.\e[0m"
    ;;

  secure)
    echo -e "\e[1;31m[!] Switching to SECURE MODE (Dreamgate)...\e[0m"
    # Harden all external interfaces
    firewall-cmd --permanent --zone=public --change-interface=$ETH
    firewall-cmd --permanent --zone=public --change-interface=$WLAN_WAN
    # Kill-switch: All traffic MUST hit the VPN
    firewall-cmd --permanent --policy hotspotToPublic --set-target REJECT
    # Force Tailscale Exit Node
    tailscale up --exit-node=$2 --exit-node-allow-lan-access=true
    firewall-cmd --reload
    echo -e "\e[1;32m[✓] Secure Mode: Tunneling through $EXIT_NODE.\e[0m"
    ;;

  *)
    echo "Usage: sudo fortress-mode [home|lean|secure]"
    ;;
esac
