#!/bin/sh
#
# IPsec router updown script for use on an Algo VPN server
#
# This script allows a router to connect in true "site-to-site" mode in
# parallel with normal Algo clients, which connect as "road warriors" (i.e.,
# with virtual IP addresses).
#
# The advantage of the "updown" script approach is that your router's local
# subnets don't need to be known in advance of deploying your Algo server.
# This script determines the subnet(s) your router wishes to send dynamically
# and sets up the necessary firewall rules.
#
# You can have multiple Phase 2 tunnels as part of a single Phase 1
# connection, so you can have more control over which traffic goes over IPsec.
# In strongSwan terms, this means you can have multiple network or host
# specifications in your router's "leftsubnet" parameter.
#
# The only part of this script that might need editing are the MSS values
# below.
#
#
# Follow these steps to install this script on an existing Algo VPN server:
#
# 1) Copy this script to /usr/local/sbin/router-updown.sh and chmod it to 0755.
#
# 2) Enable the updown plugin. Edit /etc/strongswan.d/charon/updown.conf and
# change "load = no" to "load = yes".
#
# 3) In order for strongswan to have the proper permissions to run the
# commands in this script, create a file named /etc/sudoers.d/10-strongswan
# (chmod 0440) containing (without the leading hashtag and space):
#
# strongswan ALL = NOPASSWD: /sbin/iptables, /sbin/ip6tables
#
# 4) Edit /etc/ipsec.conf and append a new "conn router" section as shown
# below (again, without the leading hashtag and space). This example assumes
# you are using the cert for an existing Algo user named "router". 
#
# pfSense requires the "CN=" before the user name in "rightid" as shown below.
# Other router software might not.
#
# conn router
#     auto=add
#     rightsourceip=
#     rightdns=
#     rightid="CN=router"
#     rightsubnet=0.0.0.0/0,::/0
#     leftsubnet=0.0.0.0/0,::/0
#     leftupdown=/usr/local/sbin/router-updown.sh
#
# 5) After changing ipsec.conf and updown.conf run "ipsec restart".
#

# For deployment on GCE, MSS_IPV4 should probably be 1316.
# These values are independent of any MSS value specified in config.cfg when
# you created your Algo server.
MSS_IPV4="1360"
MSS_IPV6="1220"

# Nothing below this point should need to be changed.

export PATH="/sbin:/bin:/usr/sbin:/usr/bin:/usr/sbin"

# Only take action if called from the "conn router" section.
if [ "${PLUTO_CONNECTION}" = "router" ]
then
	case "${PLUTO_VERB}" in

	up-client)
		IPTABLES="iptables"
		ADD_OR_DEL="-A"
		MSS=${MSS_IPV4}
		;;

	up-client-v6)
		IPTABLES="ip6tables"
		ADD_OR_DEL="-A"
		MSS=${MSS_IPV6}
		;;
								
	down-client)
		IPTABLES="iptables"
		ADD_OR_DEL="-D"
		MSS=${MSS_IPV4}
		;;

	down-client-v6)
		IPTABLES="ip6tables"
		ADD_OR_DEL="-D"
		MSS=${MSS_IPV6}
		;;
				
	esac
	
	if [ "${IPTABLES}" ]
	then
	
		sudo -n ${IPTABLES} -t mangle ${ADD_OR_DEL} FORWARD \
			-s ${PLUTO_PEER_CLIENT} -p tcp -m tcp --tcp-flags SYN,RST SYN \
			-j TCPMSS --set-mss ${MSS}

		sudo -n ${IPTABLES} -t nat ${ADD_OR_DEL} POSTROUTING \
			-s ${PLUTO_PEER_CLIENT} -m policy --pol none --dir out -j MASQUERADE

		sudo -n ${IPTABLES} -t filter ${ADD_OR_DEL} FORWARD \
			-s ${PLUTO_PEER_CLIENT} -d ${PLUTO_PEER_CLIENT} -j DROP

		sudo -n ${IPTABLES} -t filter ${ADD_OR_DEL} FORWARD \
			-m conntrack --ctstate NEW \
			-s ${PLUTO_PEER_CLIENT} -m policy --dir in --pol ipsec -j ACCEPT

	fi
fi
exit 0
