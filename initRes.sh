#!/bin/bash

systemctl stop NetworkManager
pkill dhclient
ip addr flush dev eno1
ip a add 172.18.18.2/24 dev eno1
ip route add default via 172.18.18.1
echo nameserver 8.8.8.8 >> /etc/resolv.conf
