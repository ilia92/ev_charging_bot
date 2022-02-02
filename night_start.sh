#!/bin/bash

# Description
# In this script the following timers will be used:
# Timer1 - Night Tariff start
# Timer2 - Time calculated to complete at the end of the night tariff
# Timer3 - Night tariff end

if ! [ "$2" ]; then
printf "Usage:\n./night_start.sh [night_from_to from-to] [Sonoff_IP_address] [Time_in_sesonds]\n"
printf "Example:\n./night_start.sh 22-6 192.168.1.100 3600\n"
printf "If no 3rd parameter, the timer will be started for all night hours\n"
exit
fi

# Night tariff from-to
night_from_to=$1
# IP address of the sonoff
ev_ip=$2
# Time must be in seconds
time_to_work=$3

# Disable all others timers first
jq_payload="{\"Enable\":0}"
jq_payload_encoded=`printf "%s" $jq_payload | jq -sRr @uri`
timeout $curl_timeout curl --silent http://$ev_ip/cm?cmnd=Timer1%20$jq_payload_encoded
timeout $curl_timeout curl --silent http://$ev_ip/cm?cmnd=Timer2%20$jq_payload_encoded
timeout $curl_timeout curl --silent http://$ev_ip/cm?cmnd=Timer4%20$jq_payload_encoded

start_hr=`echo $night_from_to | sed 's|-.*||g'`
start_hr_formatted=`date -d"$start_hr" +%H:%M`

end_hr=`echo $night_from_to | sed 's|.*-||g'`
end_hr_formatted=`date -d"$end_hr" +%H:%M`


if ! [ "$3" ]; then
# Case: All Night
jq_payload="{\"Enable\":1,\"Mode\":0,\"Time\":\"$start_hr_formatted\",\"Window\":0,\"Days\":\"1111111\",\"Repeat\":0,\"Output\":1,\"Action\":1}"
jq_payload_encoded=`printf "%s" $jq_payload | jq -sRr @uri`
timeout $curl_timeout curl --silent http://$ev_ip/cm?cmnd=Timer1%20$jq_payload_encoded
else
# Case: Time calculated backwards
start_hr_formatted=`date -d"$end_hr - $time_to_work seconds" +%H:%M`
jq_payload="{\"Enable\":1,\"Mode\":0,\"Time\":\"$start_hr_formatted\",\"Window\":0,\"Days\":\"1111111\",\"Repeat\":0,\"Output\":1,\"Action\":1}"
jq_payload_encoded=`printf "%s" $jq_payload | jq -sRr @uri`
timeout $curl_timeout curl --silent http://$ev_ip/cm?cmnd=Timer2%20$jq_payload_encoded
fi

jq_payload="{\"Enable\":1,\"Mode\":0,\"Time\":\"$end_hr_formatted\",\"Window\":0,\"Days\":\"1111111\",\"Repeat\":0,\"Output\":1,\"Action\":0}"
jq_payload_encoded=`printf "%s" $jq_payload | jq -sRr @uri`
timeout $curl_timeout curl --silent http://$ev_ip/cm?cmnd=Timer3%20$jq_payload_encoded
