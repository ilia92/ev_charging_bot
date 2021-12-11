# ev_charging_bot
Telegram bot for managing EV charge

### Installation and Configuration:
- A bot must be created via Godfather - https://t.me/BotFather. Get the HTTP API and save it to file .api_key
- Once created, send a message to the bot (or add it to a group). The message must start with /, e.g. /test
- Run the script ./get_chat_id.sh to get the chat_id. Save it in ev_bot.conf as variable chat_id
- Run ./get_chat_id.sh to verify if the bot can send messages. You should receive a message by the bot.
