require File.expand_path('../config/environment', __dir__)
require 'telegram/bot'
require 'pry'
require 'launchy'
require 'uri'
require 'net/http'
require 'json'

class MusBot
	def initialize(bot)
		@bot = bot
	end

	def do_the_bot_thing(message)
		id = message.from.id

		#binding.pry
    case message
    when Telegram::Bot::Types::Message

      answer_to_user(id, message.text)

    when Telegram::Bot::Types::CallbackQuery

      react_to_button(id, message.data)
    
    end
	end

  def init_user(id, username) # message.from.username
  	User.find_by(telegram_id: id) || User.create(name: username, telegram_id: id, step: 0)
    # bot.api.send_message(chat_id: id, text: 'Now you can send me youtube videos to play it on TV.')
  end

  def answer_to_user(id, message_text)
  	url = message_text[/(https:\/\/(?:www\.)?youtu\.?be(?:\.com)?.*?)(?:\s|$)/, 1]
  	return error_message(id) unless url

  	track_hash = { url: url }
  	binding.pry
    track_hash[:name] = get_track_name(get_html(track_hash))
    track = Track.find_by(url: track_hash[:url]) || Track.create(track_hash)

    play_or_queue_message(id, track)
  end

  def error_message(id)
    @bot.api.send_message(chat_id: id, text: "Sorry, I don`t understand you \xF0\x9F\x98\xB3")
    false
  end

  def play_or_queue_message(id, track)
  	keyboard = [[
            Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Play now', callback_data: JSON(play:track.id)),
            Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Add to queue', callback_data: JSON(queue:track.id)),
            ]]
  	keyboard_markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: keyboard)
  	@bot.api.send_message(chat_id: id, text: track.name, reply_markup: keyboard_markup)
  	true
  end

  def react_to_button(id, message_data)
  	json = JSON(message_data, symbolize_names: true)

    if json[:play]
      Launchy.open(Track.find(json[:play]).url)
    elsif json[:queue]
      @bot.api.send_message(chat_id: id, text: 'You send queue')
    end
  end

	def get_html(track_hash)
  	begin
    	response = Net::HTTP.get_response(URI(track_hash[:url]))
  	rescue => e
  	  return e.to_s
  	end

  	case response
  	when Net::HTTPSuccess then
  	  response.body
  	when Net::HTTPRedirection then
  		track_hash[:url] = response['location']
  	  get_html(track_hash)
  	else
   		'Not 2XX and not 3XX response :('
  	end
	end

	def get_track_name(html_content)
  	track_name = html_content[/name\s?=\s?.title.\s?content\s?=\s?"(.*?)"/, 1]
  	return track_name.force_encoding("UTF-8") if track_name

  	"Sorry, I couldn't get the song title \xF0\x9F\x98\xB0"
	end


  # def self.check_user(id)
  # 	user = User.find_by(telegram_id: id)
  # 	return user if user

  # 	advice = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard:[[{text: '/start'}]], one_time_keyboard: true )
  #   bot.api.send_message(chat_id: id, text: 'Try \'/start\' first!', reply_markup: advice)
  # end
end