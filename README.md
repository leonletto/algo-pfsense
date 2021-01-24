## Using an [AlgoVPN](https://github.com/trailofbits/algo) with [pfSense](https://www.pfsense.org)

These instructions previously only described how to route traffic from a pfSense router through an AlgoVPN using IPsec. With version 2.5 pfSense supports [WireGuard](https://www.netgate.com/blog/wireguard-for-pfsense-software.html), which makes using pfSense with an AlgoVPN easier.

### WireGuard

Some advantages of using WireGuard with pfSense:

* Configuring WireGuard is easier than IPsec.

* No changes to the AlgoVPN server or scripts are required. In order to avoid these changes NAT must be used on pfSense. NAT is always used by an AlgoVPN.

* [Policy Routing](https://docs.netgate.com/pfsense/en/latest/multiwan/policy-route.html) can be used to determine at a more granular level what traffic gets sent over the tunnel.

For instructions see [Using an AlgoVPN with pfSense using WireGuard](wireguard.md).

### IPsec

Some advantages of using IPsec with pfSense:

* The extra layer of NAT is not required.

* Works with versions of pfSense prior to 2.5.

For instructions see [Using an AlgoVPN with pfSense using IPsec](ipsec.md).
