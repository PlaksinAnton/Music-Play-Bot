require File.expand_path('../config/environment', __dir__)
require 'telegram/bot'
require 'pry'
require_relative 'bot_class'

TOKEN = '6571102624:AAG4or30Lk0mbuW2ZvKqaqZY2QMi2F5FVUw'

Telegram::Bot::Client.run(TOKEN) do |bot|
  mus_bot = MusBot.new(bot)

  bot.listen do |message| # затестить блок
    mus_bot.do_the_bot_thing(message)
  end
end

# разбить дб на домен и путь
