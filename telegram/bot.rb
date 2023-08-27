require File.expand_path('../config/environment', __dir__)
require 'telegram/bot'

TOKEN = '6571102624:AAG4or30Lk0mbuW2ZvKqaqZY2QMi2F5FVUw'

Telegram::Bot::Client.run(TOKEN) do |bot|
	bot.listen do |message|
		p message
		return
	end
end