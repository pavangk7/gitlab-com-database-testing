#!/usr/bin/env sh

#
# iptables configuration
#
# Inspired by https://dev.to/andre/docker-restricting-in--and-outbound-network-traffic-67p
#
# The following allows in- and outbound traffic
# within a certain `CIDR` (default: `10.128.0.0/24`),
# but blocks all other network traffic.
#
ACCEPT_CIDR=${ALLOWED_CIDR:-10.128.0.0/24}

iptables -A INPUT -s $ACCEPT_CIDR -j ACCEPT
iptables -A INPUT -j DROP
iptables -A OUTPUT -d $ACCEPT_CIDR -j ACCEPT
iptables -A OUTPUT -j DROP

#
# After configuring `iptables` as root, execute
# the passed command as the non-privileged `app` user.
# TODO
# sudo -u app sh -c "$@"

sh -c "$@"
