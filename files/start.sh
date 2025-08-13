#!/bin/bash

# Exit cleanly if signals are received.
trap "echo The service is terminated; exit" HUP INT QUIT TERM

if [[ -f "/etc/resolv.conf" ]]; then
    cp /etc/resolv.conf /etc/resolv.conf.bak
    umount /etc/resolv.conf &>/dev/null
    cp /etc/resolv.conf.bak /etc/resolv.conf
    rm /etc/resolv.conf.bak
fi

sed -i 's/DAEMON_ARGS=.*/DAEMON_ARGS=""/' /etc/init.d/expressvpn

output=$(service expressvpn restart)
if echo "$output" | grep -q "failed!" > /dev/null
then
    echo "Service expressvpn restart failed!"
    exit 1
fi

output=$(expect -f /expressvpn/activate.exp "$CODE")
if echo "$output" | grep -q "Please activate your account" > /dev/null || echo "$output" | grep -q "Activation failed" > /dev/null
then
    echo "Activation failed!"
    exit 1
fi

expressvpn preferences set preferred_protocol $PROTOCOL
expressvpn preferences set lightway_cipher $CIPHER
expressvpn preferences set send_diagnostics false
expressvpn preferences set block_trackers true
bash /expressvpn/uname.sh
expressvpn preferences set auto_connect true
expressvpn connect $SERVER || exit

for i in $(echo $WHITELIST_DNS | sed "s/ //g" | sed "s/,/ /g")
do
    iptables -A xvpn_dns_ip_exceptions -d ${i}/32 -p udp -m udp --dport 53 -j ACCEPT
    echo "allowing dns server traffic in iptables: ${i}"
done

# Copy resolv.conf to /shared_data for other containers on the network.
cp /etc/resolv.conf /shared_data/

while true;
do
    sleep 5m
    expressvpn status | grep -iq "Connected to"
    if [ $? -ne 0 ];
    then
        echo "ExpressVPN is disconnected. Attempting to reconnect..."
        expressvpn connect $SERVER
    fi
done
