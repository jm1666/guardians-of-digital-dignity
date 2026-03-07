#!/bin/bash
# Only run for interactive shells
[[ $- != *i* ]] && return

# 1. THE RECOVERY WARNING
if [ -f /home/fortress/FORTRESS_RECOVERY.txt ]; then
    echo -e "\n\e[1;31m[!] SECURITY ALERT: RECOVERY SECRETS DETECTED ON DISK\e[0m"
    echo -e "\e[33mSecure credentials and 'shred -u ~/FORTRESS_RECOVERY.txt' immediately.\e[0m"
fi

# 2. THE SITREP (TACTICAL VIEW)
echo -e "\n\e[1;34m--- [ FORTRESS SITREP ] ---\e[0m"
echo -e "UPTIME:    $(uptime -p)"
echo -e "TEMP:      $(vcgencmd measure_temp | cut -d= -f2)"

echo -e "\n\e[1;32m[ NETWORKING ]\e[0m"
echo -e "wlan0 (LOCAL): $(nmcli -t -f IP4.ADDRESS dev show wlan0 2>/dev/null | cut -d: -f2 || echo 'DOWN') [$(cat /sys/class/net/wlan0/address 2>/dev/null)]"
echo -e "wlan1 (SCOUT): $(nmcli -t -f IP4.ADDRESS dev show wlan1 2>/dev/null | cut -d: -f2 || echo 'DOWN') [$(cat /sys/class/net/wlan1/address 2>/dev/null)]"
echo -e "eth0 (SCOUT):  $(nmcli -t -f IP4.ADDRESS dev show eth0 2>/dev/null | cut -d: -f2 || echo 'DOWN') [$(cat /sys/class/net/wlan1/address 2>/dev/null)]"

echo -e "\n\e[1;32m[ PRIVACY ]\e[0m"
echo -e "PI-HOLE v6:    $(systemctl is-active pihole-FTL)"
echo -e "DNSCRYPT:      $(systemctl is-active dnscrypt-proxy)"
echo -e "TAILSCALE:     $(tailscale status --peers=false 2>/dev/null | head -n1 || echo 'OFFLINE')"

echo -e "\n\e[1;32m[ SECURITY ]\e[0m"
echo -e "ETH0 ZONE:     $(firewall-cmd --get-active-zones | grep -B1 eth0 | head -n1 || echo 'UNASSIGNED')"
echo -e "PUBLIC ZONE:   $(firewall-cmd --zone=public --get-target)"
echo -e "\e[1;34m---------------------------\e[0m\n"
