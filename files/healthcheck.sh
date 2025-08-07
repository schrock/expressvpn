#! /bin/bash

expressvpn status | grep -iq "Connected to"
if [ $? -ne 0 ];
then
	echo "ExpressVPN is disconnected. Attempting to reconnect..."
	expressvpn connect $SERVER
	expressvpn status | grep -iq "Connected to"
	exit $?
fi
exit 0
