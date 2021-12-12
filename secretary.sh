#!/bin/bash

DIR="$(dirname "$(readlink -f "$0")")"

source $DIR/ev_bot.conf
refresh_rate=1
evs_file_read=`cat $DIR/evs.txt | cut -f1 -d"#" | sed '/^\s*$/d'`

if [ -z "$STY" ]; then
printf "Bot started in background\n"
screen -S secretary_bot -X quit > /dev/null
exec screen -dm -S secretary_bot /bin/bash $0
fi

sendtext() {
curl -X POST https://api.telegram.org/bot$api_key/sendMessage -d chat_id=$chat_id -d text="$1" >/dev/null 2>&1 ;
}

evgrep() {
ev_name=$1
if ! [[ "$evname" ]]; then
ev_chosen=`printf "$evs_file_read" | head -1`
else
ev_chosen=`printf "$evs_file_read" | grep "$ev_name"`
fi

ev_name=`printf "$ev_chosen" | awk {'print $1'}`
ev_ip=`printf "$ev_chosen" | awk {'print $2'}`
ev_full_power=`printf "$ev_chosen" | awk {'print $3'}`
ev_charger_power=`printf "$ev_chosen" | awk {'print $4'}`
ev_blocks=`printf "$ev_chosen" | awk {'print $5'}`
time_per_block=$(($ev_full_power*60/$ev_blocks/$ev_charger_power))
#printf "Time per block: $time_per_block\n"
}

start() {
input_time=`echo $1 | tr '[:upper:]' '[:lower:]'`

# Check current date
sonoff_time=`curl --silent http://$ev_ip/cm?cmnd=Time%203 | jq .Time`
sonoff_timezone=`curl --silent http://$ev_ip/cm?cmnd=Timezone | jq -r .Timezone`

# Some hints if we need to work with timer sets:
# opop=`echo '{"Enable":0,"Mode":0,"Time":"23:10","Window":0,"Days":"1111111","Repeat":0,"Output":1,"Action":1}' | jq -sRr @uri`
# curl --silent 192.168.1.100/cm?cmnd=Timer1%20$opop
#jq_payload="{"Enable":1,"Mode":0,"Time":"23:10","Window":0,"Days":"1111111","Repeat":0,"Output":1,"Action":1}"

case "$input_time" in
	"") curl --silent http://$ev_ip/cm?cmnd=Power%201 ;;
	*m|*min|*minutes) input_time=`echo $input_time | grep -Po "\\d+"` ; curl --silent http://$ev_ip/cm?cmnd=Power%201 ; remaining=`curl --silent http://$ev_ip/cm?cmnd=PulseTime1%20$(($input_time*60)) | jq .PulseTime1.Remaining`;printf "\nStarted for $((($remaining+5)/60)) minutes" ;;
	*h|*hr|*hours) input_time=`echo $input_time | grep -Po "\\d+"` ; curl --silent http://$ev_ip/cm?cmnd=Power%201 ; remaining=`curl --silent http://$ev_ip/cm?cmnd=PulseTime1%20$(($input_time*3600)) | jq .PulseTime1.Remaining`;printf "\nStarted for $((($remaining+5)/3600)) hour" ;;
	*)
    if [[ $myvar =~ [^[:digit:]] ]]
    then
        printf "Unknown parameter"
    else
        input_time=$(($time_per_block*$input_time)) ; curl --silent http://$ev_ip/cm?cmnd=Power%201 ; remaining=`curl --silent http://$ev_ip/cm?cmnd=PulseTime1%20$(($input_time*60)) | jq .PulseTime1.Remaining` ; printf "\nStarted for $((($remaining+5)/60)) minutes"
    fi
    ;;

esac
}

#curl --silent https://api.telegram.org/bot$api_key/getMe | jq
username=`curl --silent https://api.telegram.org/bot$api_key/getMe | jq -M -r .result.username`
date

help_section="
/help - Prints this text
/start - starts charging
Valid inputs for /start:
/start 4 - charges 4 blocks (roughly calculated)
/start 2000wh - charge 2000wh energy
/start 60m - charge for 60minutes
/start 1h - charge for 1hour
/night - same as /start - but starts charging on night tariff. Calculates to be in last hours
/stop - stops charging
/remaining - shows remaining time (in minutes)
/checkclock - check sonoff time
/updateclock - update sonoff time
"

while [ 1 ]
do

curr_message=`curl --silent -s "https://api.telegram.org/bot$api_key/getUpdates?timeout=600&offset=$update_id"`
last_upd_id=`printf "$curr_message" |  jq '.result | .[] | .update_id' | tail -1`

if [[ $update_id -le $last_upd_id ]]; then
update_id=$((last_upd_id+1))

curr_message_text=`printf "$curr_message" | jq -r '.result | .[].message.text' | tail -1`

if [[ "$curr_message_text" ]]; then
printf "Message received: $curr_message_text\n"
# clear last message
curl -s "https://api.telegram.org/bot$api_key/getUpdates?offset=$update_id"  >/dev/null 2>&1
fi

command=`echo $curr_message_text | grep -o '\/.*' | awk {'print $1'} | sed "s|@$username||g"`
arg=`echo $curr_message_text | awk {'print $2" "$3" "$4'}`

evgrep

case "$command" in
	("") ;;
	("/test") result="test PASS!" ;;
        ("/help") result="$help_section" ;;
	("/start") result=`start $arg` ;;
	("/night") result="Scheduled for the night" ;;
        ("/stop") result=`curl --silent http://$ev_ip/cm?cmnd=Power%200` ;;
        ("/remaining") result=`printf "\nMore $(($(curl --silent http://$ev_ip/cm?cmnd=PulseTime1 | jq .PulseTime1.Remaining)/60)) minutes left"` ;;
	("/checkclock") result=`curl --silent http://$ev_ip/cm?cmnd=Time%201 | jq -r .[]`;;
        ("/updateclock") pc_date=`date +"%:z"` result=`curl --silent http://$ev_ip/cm?cmnd=timezone%20$pc_date`;;
	(*) result="Unknown command!" ;;
esac

if [[ "$result" ]]; then
printf "Result:\n$result"
sendtext "$result"
fi

printf "\n\n"
fi

sleep $refresh_rate
done
