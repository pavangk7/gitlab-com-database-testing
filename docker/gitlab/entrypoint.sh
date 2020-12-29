#!/usr/bin/env sh

#
# iptables configuration
#
# Inspired by https://dev.to/andre/docker-restricting-in--and-outbound-network-traffic-67p
#
# The following allows in- and outbound traffic
# within certain CIDRs,
# but blocks all other network traffic.

ACCEPT_CIDR="127.16.0.0/12"

iptables -A INPUT -s $ACCEPT_CIDR -j ACCEPT
iptables -A INPUT -j DROP
iptables -A OUTPUT -d $ACCEPT_CIDR -j ACCEPT
iptables -A OUTPUT -j DROP

#
# After configuring `iptables` as root, execute
# the passed command as the non-privileged `app` user.

sudo -u gitlab "$@"