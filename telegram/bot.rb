require File.expand_path('../config/environment', __dir__)
require 'telegram/bot'
require 'pry'
require 'launchy'
require 'uri'
require 'net/http'
require 'json'

TOKEN = '6571102624:AAG4or30Lk0mbuW2ZvKqaqZY2QMi2F5FVUw'

# help func
def get_html(url)
  begin
    response = Net::HTTP.get_response(URI(url))
  rescue => e
    return e.to_s
  end

  case response
  when Net::HTTPSuccess then
    response.body
  when Net::HTTPRedirection then
    get_html(response['location'])
  else
    'Not 2XX and not 3XX response :('
  end
end

def get_track_name(html_content)
  track_name = html_content[/name\s?=\s?.title.\s?content\s?=\s?"(.*?)"/, 1]
  binding.pry
  return track_name.force_encoding("UTF-8") if track_name

  "Sorry, I couldn't get the song title \xF0\x9F\x98\xB0"
end

def url_keyboard(track_id)
  keyboard = [[
            Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Play now', callback_data: JSON(play:track_id)),
            Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Add to queue', callback_data: JSON(queue:track_id)),
            ]]
  Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: keyboard)
end

# main
Telegram::Bot::Client.run(TOKEN) do |bot|
  bot.listen do |message|
    id = message.from.id
    if message.class == Telegram::Bot::Types::Message

      if message.text == '/start'
        User.create(name: message.from.username, telegram_id: id, step: 0) unless User.find_by(telegram_id: id)
        bot.api.send_message(chat_id: id, text: 'Now you can send me youtube videos to play it on TV.')

      elsif message.text =~ /https:\/\/(?:www\.)?youtu\.?be(?:\.com)?/
        if user = User.find_by(telegram_id: id)
          track_name = get_track_name(get_html(message.text))
          track = Track.find_by(url: message.text) || Track.create(name: track_name, url: message.text)

          bot.api.send_message(chat_id: id, text: track.name, reply_markup: url_keyboard(track.id))

        else
          advice = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard:[[{text: '/start'}]], one_time_keyboard: true )
          bot.api.send_message(chat_id: id, text: 'Try \'/start\' first!', reply_markup: advice)
        end

      else
        bot.api.send_message(chat_id: id, text: "Sorry, I don`t understand you \xF0\x9F\x98\xB3")
      end

    else #Telegram::Bot::Types::CallbackQuery
      json = JSON(message.data, symbolize_names: true)
      if json[:play]
        Launchy.open(Track.find(json[:play]).url)
      elsif json[:queue]
        bot.api.send_message(chat_id: id, text: 'You send queue')
      end
    end
  end
end

# как изменить бд?

# разбить дб на домен и путь
# устроить возможность пересылать сообщение
# улучшить регулярку?
