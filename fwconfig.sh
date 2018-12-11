#!/bin/bash
iptables -F
iptables -F -t nat 
iptables -F -t mangle

#Delete CHAINS :
iptables -X
 
#New CHAINS
#ICI BAD represent internet:
iptables -N BAD_DMZ
iptables -N DMZ_BAD
iptables -N DMZ_LAN
iptables -N LAN_BAD
iptables -N LAN_DMZ

#Exercice d'ecriture
#Pour la dmz seulement besoin de BAD_ME tout ce qui vient de l'extérieur est dangereux
iptables -N BAD_ME
iptables -N DMZ_ME
iptables -N LAN_ME

#Default policies
iptables -P INPUT DROP
iptables -P OUTPUT ACCEPT
iptables -P FORWARD DROP 

EXT_ADMIN_PCO="127.0.0.1"

#NAT des addresses interface eno1 -> postrouting Masquerade pour le nat
iptables -t nat -A POSTROUTING -o eno1 -j MASQUERADE
iptables -t nat -A PREROUTING -i eno1 -p tcp --dport 8080 -j DNAT --to-destination 172.18.18.2:8080

iptables -A LAN_ME -p tcp --dport ssh -j ACCEPT
iptables -A LAN_ME -m limit --limit 3/s -j LOG --log-prefix "LAN_ME " 
iptables -A LAN_ME -p tcp -j REJECT --reject-with tcp-reset
iptables -A LAN_ME -j REJECT

iptables -A DMZ_ME -m limit --limit 3/s -j LOG --log-prefix "DMZ_ME " 
iptables -A DMZ_ME -p tcp -j REJECT --reject-with tcp-reset
iptables -A DMZ_ME -j REJECT

iptables -A BAD_ME -s $EXT_ADMIN_PCO -p tcp --dport ssh -j ACCEPT
iptables -A BAD_ME -m limit --limit 3/s -j LOG --log-prefix "BAD_ME " 
iptables -A BAD_ME -j DROP

iptables -A DMZ_BAD -p tcp -m multiport --ports 110,143,25,443,8080 -j ACCEPT
iptables -A DMZ_BAD -p udp --dport domain -j ACCEPT
iptables -A DMZ_BAD -m limit --limit 3/s -j LOG --log-prefix "DMZ_BAD " 
iptables -A DMZ_BAD -j DROP

iptables -A BAD_DMZ -p tcp -m multiport --ports 110,143,25,443,8080 -j ACCEPT
iptables -A BAD_DMZ -p udp --dport domain -j ACCEPT
iptables -A BAD_DMZ -m limit --limit 3/s -j LOG --log-prefix "DMZ_BAD " 
iptables -A BAD_DMZ -j DROP

iptables -A LAN_DMZ -p tcp --dport 8080 -j ACCEPT
iptables -A LAN_DMZ -p udp --dport domain -j ACCEPT
iptables -A LAN_DMZ -m limit --limit 3/s -j LOG --log-prefix "DMZ_BAD " 
iptables -A LAN_DMZ -j DROP

#INPUT Rules to apply
iptables -A INPUT -m state --state INVALID -j DROP
#iptables -A INPUT -p tcp ! --syn -m state --state NEW,RELATED -j DROP
iptables -A INPUT -m limit --limit 3/s -p tcp ! --tcp-flags ALL SYN -m state --state NEW,RELATED -j LOG --log-prefix "ONLY_SYN " 
iptables -A INPUT -p tcp ! --tcp-flags ALL SYN -m state --state NEW,RELATED -j DROP
iptables -A INPUT -m limit --limit 3/s -p tcp ! --tcp-option 2 -m state --state NEW,RELATED  -j LOG --log-prefix "NO_MSS"
iptables -A INPUT -p tcp ! --tcp-option 2 -m state --state NEW,RELATED  -j DROP
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
#iptables -A INPUT -p tcp --dport 111 -j ACCEPT
#Idem les règles pour tous dmz a seulement besoins des 2 BAD_ME
iptables -A INPUT -i enp6s2 -j LAN_ME 
iptables -A INPUT -i enp6s1 -j DMZ_ME 
iptables -A INPUT -i eno1 -j BAD_ME 
iptables -A INPUT -i lo -j BAD_ME 
iptables -A INPUT -m limit --limit 3/second -j LOG --log-prefix "INPUT_BAD" 
iptables -A INPUT -j DROP 

#FORWARD Rules to apply

iptables -A FORWARD -m state --state INVALID -j DROP
iptables -A FORWARD -m limit --limit 3/s -p tcp ! --tcp-flags ALL SYN -m state --state NEW,RELATED -j LOG --log-prefix "ONLY_SYN " 
iptables -A FORWARD -p tcp ! --tcp-flags ALL SYN -m state --state NEW,RELATED -j DROP
iptables -A FORWARD -m limit --limit 3/s -p tcp ! --tcp-option 2 -m state --state NEW,RELATED  -j LOG --log-prefix "NO_MSS"
iptables -A FORWARD -p tcp ! --tcp-option 2 -m state --state NEW,RELATED  -j DROP
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

iptables -A FORWARD -i enp6s2 -o enp6s1 -j LAN_DMZ
iptables -A FORWARD -i enp6s2 -o eno1 -j LAN_BAD
iptables -A FORWARD -i enp6s1 -o enp6s2 -j DMZ_LAN
iptables -A FORWARD -i enp6s1 -o eno1 -j DMZ_BAD
iptables -A FORWARD -i eno1 -o enp6s1 -j BAD_DMZ

#iptables -A FORWARD -i lo -j BAD_ME ==>PAS DE SENS POUR LOOPBACK
iptables -A FORWARD -m limit --limit 3/second -j LOG --log-prefix "INPUT_BAD" 
iptables -A FORWARD -j DROP 




