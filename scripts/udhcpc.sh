#!/bin/sh
case "$1" in
 "bound"|"renew")
  ifconfig $interface $ip netmask $subnet ${broadcast:+broadcast $broadcast} up 2>/dev/null
  if [ -n "$router" ] ; then
   while route del default dev $interface 2>/dev/null ; do : ; done
   for gw in $router ; do
    route add default gw $gw dev $interface
    break
   done
  fi
  if [ -n "$dns" ] || [ -n "$domain" ] ; then
   {
    [ -n "$domain" ] && echo "search $domain"
    for ns in $dns ; do echo "nameserver $ns" ; done
   } > /etc/resolv.conf
  fi
  ;;
 "deconfig")
  ifconfig $interface 0.0.0.0 2>/dev/null
  while route del default dev $interface 2>/dev/null ; do : ; done
  ;;
 "leasefail")
  echo "udhcpc lease failed on $interface"
  ;;
 *)
  echo "udhcpc unsupported case $1"
  ;;
esac
exit 0
