#!/bin/bash

DIR="$(dirname "$(readlink -f "$0")")"

source $DIR/ev_bot.conf
api_key=`cat "$api_key_file"`

timeout $curl_timeout curl --silent https://api.telegram.org/bot$api_key/getMe | jq

chat_id=`timeout $curl_timeout curl --silent -s "https://api.telegram.org/bot$api_key/getUpdates" | jq .result[].message.chat.id`

printf "Chat ID/s:\n$chat_id\n\n"

printf "Sending message:\n"
timeout $curl_timeout curl --silent -X POST https://api.telegram.org/bot$api_key/sendMessage -d chat_id=$chat_id -d text="This bot works!" |jq

