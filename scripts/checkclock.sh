#/bin/bash

sonoff_ip=$1

curl --silent http://${sonoff_ip}/
