#!/bin/bash

DIR="$(dirname "$(readlink -f "$0")")"

source $DIR/ev_bot.conf
api_key=`cat "$api_key_file"`
refresh_rate=1
evs_file_read=`cat $DIR/evs.txt | cut -f1 -d"#" | sed '/^\s*$/d'`

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
block_power=`echo $ev_full_power/$ev_blocks | bc -l`
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
/night - same as /start - but starts charging on night tariff. Calculates to be in last hours
/stop - stops charging
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
	("/start") result="Starting" ;;
	("/stop") result="Stopping" ;;
	("/night") result="Scheduled for the night" ;;
#/stop - stops charging
	("/checkclock") result=`curl --silent http://$ev_ip/cm?cmnd=time | jq -r .[]`;;
        ("/updateclock") pc_date=`date +"%:z"` result=`curl --silent http://$ev_ip/cm?cmnd=timezone%20$pc_date`;;
	(*) result="Unknown command!" ;;
esac

if [[ "$result" ]]; then
#printf "Result:\n$result"
sendtext "$result"
fi

printf "\n\n"
fi

sleep $refresh_rate
done
