#!/bin/bash

# Description
# This scripts enables Timer4 as END time and starts the Sonoff Immediately

if ! [ "$2" ]; then
printf "Usage:\n./start.sh [Sonoff_IP_address] [Time_in_sesonds]\n"
exit
fi

# IP address of the sonoff
ev_ip=$1
# Time must be in seconds
time_to_add=$2

get_time=`timeout $curl_timeout curl --silent http://$ev_ip/cm?cmnd=time%202`
get_time_epoch=`printf "$get_time" | jq .Epoch`

# Disable all other timers first
jq_payload="{\"Enable\":0}"
jq_payload_encoded=`printf "%s" $jq_payload | jq -sRr @uri`
timeout $curl_timeout curl --silent http://$ev_ip/cm?cmnd=Timer1%20$jq_payload_encoded
timeout $curl_timeout curl --silent http://$ev_ip/cm?cmnd=Timer2%20$jq_payload_encoded
timeout $curl_timeout curl --silent http://$ev_ip/cm?cmnd=Timer3%20$jq_payload_encoded

# date -d @1639363996 +%H:%M
# date -d"2021-12-13T04:49:16" +%s

# Some hints if we need to work with timer sets:
# opop=`echo '{"Enable":0,"Mode":0,"Time":"23:10","Window":0,"Days":"1111111","Repeat":0,"Output":1,"Action":1}' | jq -sRr @uri`
# timeout $curl_timeout curl --silent $ev_ip/cm?cmnd=Timer1%20$opop
# jq_payload="{"Enable":1,"Mode":0,"Time":"23:10","Window":0,"Days":"1111111","Repeat":0,"Output":1,"Action":1}"

time_for_payload=`date -d @$(($get_time_epoch+$time_to_add)) +%H:%M`
jq_payload_end="{\"Enable\":1,\"Mode\":0,\"Time\":\"$time_for_payload\",\"Window\":0,\"Days\":\"1111111\",\"Repeat\":0,\"Output\":1,\"Action\":0}"
jq_payload_end_encoded=`printf "%s" $jq_payload_end | jq -sRr @uri`

# Some Dbug printfs
#printf "Payload:\n%s\n" $jq_payload_end
#printf "Payload ENCODED:\n%s\n" $jq_payload_end_encoded

timeout $curl_timeout curl --silent http://$ev_ip/cm?cmnd=Power%201 http://$ev_ip/cm?cmnd=Timer4%20$jq_payload_end_encoded
