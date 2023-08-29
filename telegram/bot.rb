require File.expand_path('../config/environment', __dir__)
require 'telegram/bot'
require 'pry'
require 'launchy'

TOKEN = '6571102624:AAG4or30Lk0mbuW2ZvKqaqZY2QMi2F5FVUw'

Telegram::Bot::Client.run(TOKEN) do |bot|
	bot.listen do |message|
		u_data = message.from
		# binding.pry
		user = User.find_by(telegram_id: u_data.id) || User.create(name: u_data.username, telegram_id: u_data.id, step: 0)
		if message.text == '/show'
    	bot.api.send_message(chat_id: message.chat.id, text: 'Hi, pidor ;)')
   	elsif message.text =~ /https:\/\/www\.youtube\.com/
   		Launchy.open(message.text)
   	else
    	bot.api.send_message(chat_id: message.chat.id, text: 'Я тебя не понимаю :(')
   	end
	end
end
