# ev_charging_bot
Telegram bot for managing EV charge
It uses custom Firmware [Tasmota](https://tasmota.github.io/docs/About/) Flashed on [Sonoff POW R2](https://sonoff.tech/product/diy-smart-switch/powr2/). Tested on version Tasmota 10.1.0.

### Installation and Configuration:
- A bot must be created via [Godfather](https://t.me/BotFather). Get the HTTP API and save it as variable api_key= in the ev_bot.conf file
- Once created, send a message to the bot (or add it to a group). The message must start with /, e.g. /test
- Run the script ./get_chat_id.sh to get the chat_id. Save it in ev_bot.conf as variable chat_id
- Run ./get_chat_id.sh to verify if the bot can send messages. You should receive a message by the bot.

### Design and logic
- Timer1 is used for start time of the Night Tariff - /allnight
- Timer2 is used for start in the last hours - e.g. /night 1h
- Timer3 is always the end of Night Tariff. It's only Active when /night or /allnight is activated
- Timer4 is used as end time, when /start is activated
