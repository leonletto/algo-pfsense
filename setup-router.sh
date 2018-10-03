#!/bin/bash
#
# Configure an Algo VPN server to accept IPsec connections from a router
# such as pfSense, based on the instructions located here:
#
# https://github.com/davidemyers/algo-pfsense
#
# Run this as root on an already installed Algo VPN server.
#

SCRIPT="https://raw.githubusercontent.com/davidemyers/algo-pfsense/master/router-updown.sh"

if [[ ${UID} -ne 0 ]]; then
    echo "You must be root to run this."
    exit 1
fi

# Don't run if the script is already present.
if [[ ! -e /usr/local/sbin/router-updown.sh ]]; then
    # Install the router-updown.sh script from the repository.
    wget -O /usr/local/sbin/router-updown.sh ${SCRIPT}
    chmod 0755 /usr/local/sbin/router-updown.sh

    # Allow strongswan to run firewall commands without a password.
    echo "strongswan ALL = NOPASSWD: /sbin/iptables, /sbin/ip6tables" > /etc/sudoers.d/10-strongswan
    chmod 0440 /etc/sudoers.d/10-strongswan

    # Enable the strongswan updown plugin.
    perl -p -i -e 's/load = no/load = yes/' /etc/strongswan.d/charon/updown.conf

    # Add a new connection type to ipsec.conf.
    cat >> /etc/ipsec.conf <<-'EOF'

	conn router
	    auto=add
	    rightsourceip=
	    rightdns=
	    rightid="CN=router"
	    rightsubnet=0.0.0.0/0,::/0
	    leftsubnet=0.0.0.0/0,::/0
	    leftupdown=/usr/local/sbin/router-updown.sh
	EOF

    # Restart IPsec.
    ipsec restart
fi
