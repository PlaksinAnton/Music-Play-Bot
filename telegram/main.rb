require File.expand_path('../config/environment', __dir__)
require 'telegram/bot'
require 'pry'
require_relative 'mus_bot'

Telegram::Bot::Client.run(ENV['TOKEN']) do |bot|
  mus_bot = MusBot.new(bot)

  bot.listen { |message| mus_bot.do_the_bot_thing(message) }
end
