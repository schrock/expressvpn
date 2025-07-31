#! /bin/bash

expressvpn status | grep -iq "Connected to"
exit $?
