ADMIN_SEL="127.0.0.1" 

# IPTABLES FLUSH
iptables -F
iptables -F -t nat
iptables -F -t mangle

# DELETE CHAINS
iptables -X

# NEW CHAINS
# # FORWARD
iptables -N BAD_DMZ 
iptables -N DMZ_BAD
iptables -N DMZ_LAN
iptables -N LAN_BAD
iptables -N LAN_DMZ

# # INPUT

iptables -N BAD_ME
iptables -N LAN_ME
iptables -N DMZ_ME

# DEFAULT POLICY

iptables -P INPUT DROP
iptables -P OUTPUT ACCEPT
iptables -P FORWARD DROP

# Regle de masque pour la DMZ (Accès internet)

iptables -t nat -A POSTROUTING -o enp6s1 -j MASQUERADE

# # INPUT: LAN to ME rules
iptables -A LAN_ME -p tcp --dport ssh -j ACCEPT 
iptables -A LAN_ME -m limit --limit 3/s -j LOG --log-prefix "LAN ME BAD "
iptables -A LAN_ME -p tcp -j REJECT --reject-with tcp-reset
iptables -A LAN_ME -j REJECT

# # INPUT: DMZ to ME rules
iptables -A DMZ_ME -m limit --limit 3/s -j LOG --log-prefix "DMZ ME BAD "
iptables -A DMZ_ME -p tcp -j REJECT --reject-with tcp-reset
iptables -A DMZ_ME -j REJECT

# # INPUT: BAD to ME Rules
iptables -A BAD_ME -s $EXT_ADMIN_SEL -p tcp --dport ssh -j ACCEPT 
iptables -A BAD_ME -m limit --limit 3/s -j LOG --log-prefix "BAD ME BAD "
iptables -A BAD_ME -j DROP

# INPUT RULES
iptables -A INPUT -m state --state INVALID -j DROP
iptables -A INPUT -m state --state NEW,RELATED -p tcp ! --syn -j DROP
iptables -A INPUT -p tcp ! --tcp-flags ALL SYN  -m state --state NEW,RELATED -j DROP
iptables -A INPUT -p tcp ! --tcp-option 2 -m state --state NEW,RELATED -j DROP
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

iptables -A INPUT -i eno1 -j LAN_ME
iptables -A INPUT -i enp6s0  -j DMZ_ME
iptables -A INPUT -i enp6s1  -j BAD_ME

# # INPUT: LOOPBACK RULE
iptables -A INPUT -i lo -j ACCEPT

iptables -A INPUT -m limit --limit 3/s -j LOG --log-prefix "INPUT BAD "
iptables -A INPUT -j DROP

# # INPUT: BAD to DMZ rules
iptables -A BAD_DMZ -p tcp --dport 1234 -j ACCEPT
iptables -A BAD_DMZ -m limit --limit 3/s -j LOG --log-prefix "BAD to DMZ BAD "
iptables -A BAD_DMZ -p tcp -j REJECT --reject-with tcp-reset
iptables -A BAD_DMZ -j REJECT

# # INPUT: DMZ to BAD rules
#iptables -A DMZ_BAD -p tcp --dport 25 -j ACCEPT
iptables -A DMZ_BAD -m limit --limit 3/s -j LOG --log-prefix "DMZ to BAD BAD "
iptables -A DMZ_BAD -j ACCEPT

# # INPUT: DMZ to LAN rules
iptables -A DMZ_LAN -p tcp --dport 25 -j ACCEPT
iptables -A DMZ_LAN -j REJECT

# # INPUT: LAN to BAD rules
iptables -A LAN_BAD -p tcp --dport 80 -j ACCEPT
iptables -A LAN_BAD -j REJECT

# # INPUT: LAN to DMZ rules
iptables -A LAN_DMZ -p tcp --dport 25 -j ACCEPT
iptables -A LAN_DMZ -j REJECT

# # INPUT: 

# FORWARD
iptables -A FORWARD -m state --state INVALID -j DROP
iptables -A FORWARD -m state --state NEW,RELATED -p tcp ! --syn -j DROP
iptables -A FORWARD -p tcp ! --tcp-flags ALL SYN  -m state --state NEW,RELATED -j DROP
iptables -A FORWARD -p tcp ! --tcp-option 2 -m state --state NEW,RELATED -j DROP
iptables -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

iptables -A FORWARD -i enp6s1 -o enp6s0 -j BAD_DMZ
iptables -A FORWARD -i enp6s0 -o enp6s1 -j DMZ_BAD
iptables -A FORWARD -i enp6s0 -o eno1 -j DMZ_LAN
iptables -A FORWARD -i eno1 -o enp6s1 -j LAN_BAD
iptables -A FORWARD -i eno1 -o enp6s0 -j LAN_DMZ

iptables -A FORWARD -m limit --limit 3/s -j LOG --log-prefix "FORWARD BAD "
iptables -A FORWARD -j DROP

