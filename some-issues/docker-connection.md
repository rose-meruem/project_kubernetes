# INC-000 — Docker bridge networking blocked by nftables

During local Phase 1 development, Docker builds failed because containers could not reach PyPI.
The host had working internet access, but containers on Docker bridge networks could not reach external IPs or resolve DNS.

The issue was traced through DNS tests, container routing checks, Docker bridge validation, iptables NAT inspection, FORWARD chain counters, rp_filter checks, and native nftables inspection.

Root cause: a native nftables `inet filter forward` chain had `policy drop`, which blocked Docker bridge forwarding before NAT/postrouting.

Fix: explicitly allow Docker private bridge subnets from `172.16.0.0/12` to the host outbound interface `wlan0`, and allow established return traffic.

Validation: `docker run --rm alpine ping -c 3 1.1.1.1`, `nslookup pypi.org`, and `wget https://pypi.org` succeeded after the nftables rule update.
