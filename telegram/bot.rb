require File.expand_path('../config/environment', __dir__)
require 'telegram/bot'
require 'pry'
require 'launchy'
require 'uri'
require 'net/http'

TOKEN = '6571102624:AAG4or30Lk0mbuW2ZvKqaqZY2QMi2F5FVUw'

# help func
def get_track_name(url)
  response = Net::HTTP.get(URI(url))
  response[/name\s?=\s?.title.\s?content\s?=\s?"(.*?)"/, 1].force_encoding("UTF-8")
end

def url_keyboard
  keyboard = [[
            Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Play now', callback_data: 'play'),
            Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Add to queue', callback_data: 'queue'),
            ]]
  Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: keyboard)
end

# main
Telegram::Bot::Client.run(TOKEN) do |bot|
  bot.listen do |message|
    binding.pry
    if message.class == Telegram::Bot::Types::Message

      if message.text == '/start'
        data = message.from
        User.create(name: data.username, telegram_id: data.id, step: 0) unless User.find_by(telegram_id: data.id)
        bot.api.send_message(chat_id: message.chat.id, text: 'Now you can send me youtube videos to play it on TV.')

      elsif message.text =~ /https:\/\/www\.youtube\.com/
        # Launchy.open(message.text)
        if user = User.find_by(telegram_id: message.from.id)
          user.update(step: 1)
          bot.api.send_message(chat_id: message.chat.id, text: 'What should I do?', reply_markup: url_keyboard)
          Track.create(name: get_track_name(message.text), url: message.text) unless Track.find_by(url: message.text)

        else
          advice = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard:[[{text: '/start'}]], one_time_keyboard: true )
          bot.api.send_message(chat_id: message.chat.id, text: 'Try \'/start\' first!', reply_markup: advice)
        end

      else
        bot.api.send_message(chat_id: message.chat.id, text: 'I don`t understand u:(')
      end

    else #Telegram::Bot::Types::CallbackQuery
      case message.data
      when 'play'
        bot.api.send_message(chat_id: message.from.id, text: 'You send play')
      when 'queue'
        bot.api.send_message(chat_id: message.from.id, text: 'You send queue')
      end
    end
  end
end
