require File.expand_path('../config/environment', __dir__)
require 'telegram/bot'
require 'pry'
require 'launchy'
require 'uri'
require 'net/http'
require 'json'

class MusBot
	EMOJI = {
		memo: "\xF0\x9F\x93\x9D",
		repeat: "\xF0\x9F\x94\x81",
		flushed: "\xF0\x9F\x98\xB3",
		eyes: "\xF0\x9F\x91\x80",
		sweat: "\xF0\x9F\x98\xB0",
	}.freeze

	def initialize(bot)
		@bot = bot
	end

	def init_values(message)
		@id = message.from.id
		@user = User.find_by(telegram_id: @id) || User.create(name: message.from.username, telegram_id: @id)
	end

	def do_the_bot_thing(message)
		init_values(message)

    case message
    when Telegram::Bot::Types::Message

      answer_to_user(message)

    when Telegram::Bot::Types::CallbackQuery

      react_to_button(message)
    
    end
	end

  def answer_to_user(message)
  	return handle_start(@id,  @user.name) if message.text	== '/start'

  	return handle_history(@id, @user) if message.text	== '/history'

  	return handle_queue(@id, @user) if message.text	== '/saved'

		url = message.text[/(https:\/\/(?:www\.)?youtu\.?be(?:\.com)?.*?)(?:\s|$)/, 1]
		return error_message(@id) unless url

		track_hash = { url: url }
		track_hash[:name] = get_track_name(get_html(track_hash))
		track = Track.find_by(url: track_hash[:url]) || Track.create(track_hash)
	
		send_play_message(@id, track)
	end

	def handle_start(id, username)
		if User.find_by(telegram_id: id)
			@bot.api.send_message(chat_id: id, text: EMOJI[:eyes])
		else
			User.create(name: username, telegram_id: id, step: 0)
			@bot.api.send_message(chat_id: id, text: 'You can send me youtube videos to play it on the TV.')
		end
	end

	def handle_history(id, user)
		delete_message(id, user.history_id)
  	send_list_message(id, user, PlayedTrack)
	end

	def handle_queue(id, user)
		delete_message(id, user.queue_id)
		send_list_message(id, user, QueuedTrack)
	end

	def send_play_message(id, track)
		keyboard = [[
	          Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Play now', callback_data: make_callback_json('play', track.id)),
	          Telegram::Bot::Types::InlineKeyboardButton.new(text: 'To saved', callback_data: make_callback_json('queue', track.id)),
	          ]]
		keyboard_markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: keyboard)
		@bot.api.send_message(chat_id: id, text: track.name, reply_markup: keyboard_markup)
		true
	end

	def send_list_message(id, user, data_class)
		markup = create_list_markup(data_class)
		markup.inline_keyboard.empty?
		if data_class == PlayedTrack
			bot_message = @bot.api.send_message(chat_id: id, text: "#{EMOJI[:repeat]}Recently played tracks:", reply_markup: markup)
			user.update(history_id: bot_message.dig('result', 'message_id'))
		elsif data_class == QueuedTrack
			bot_message = @bot.api.send_message(chat_id: id, text: "#{EMOJI[:memo]}Queued tracks:", reply_markup: markup)
			user.update(queue_id: bot_message.dig('result', 'message_id'))
		end
	end

	def delete_message(id, message_id)
		return 'There is no such message' unless message_id
		@bot.api.delete_message(chat_id: id, message_id: message_id) rescue 'Message is too old'
	end

	def update_list_message(id, message_id, data_class)
		return 'There is no such message' unless message_id
		markup = create_list_markup(data_class)
		@bot.api.edit_message_reply_markup(chat_id: id, message_id: message_id, reply_markup: markup) rescue 'Message is too old'
	end

	def create_list_markup(data_class)
		keyboard = data_class.order(created_at: :desc).limit(8).map.with_index do |t, i|
			name_in_button = t.track.name.size > 50 ? t.track.name[..50]+'..' : t.track.name
			button_text = "#{name_in_button} - #{t.user.name}"
			json = make_callback_json('play', t.track.id, data_class.to_s, t.id)
			[Telegram::Bot::Types::InlineKeyboardButton.new(text: button_text, callback_data: json)]
		end
		keyboard << [Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Empty', callback_data: '{}')] if keyboard.empty?
		Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: keyboard)
	end

	def react_to_button(message)
		json = JSON(message.data, symbolize_names: true)

		case json[:type]
		when 'play'
			@bot.api.send_message(chat_id: @id, text: 'Track played')
			# Launchy.open(Track.find(json[:play]).url)
			PlayedTrack.create(track_id: json[:id], user_id: @user.id)
			QueuedTrack.destroy(json[:p_id]) if json[:origin] == 'QueuedTrack'
	    update_list_message(@id, @user.history_id, PlayedTrack)
	    update_list_message(@id, @user.queue_id, QueuedTrack)
	  when 'queue'
	    @bot.api.send_message(chat_id: @id, text: 'You\'ve saved this clip.')
	    QueuedTrack.create(track_id: json[:id], user_id: @user.id)
	    update_list_message(@id, @user.queue_id, QueuedTrack)
	  end
	end

	def error_message(id)
		@bot.api.send_message(chat_id: id, text: "Sorry, I don`t understand you #{EMOJI[:flushed]}")
		false
	end

  def make_callback_json(type, track_id, origin = 'url', primary_id = nil)
  	JSON(type: type, id: track_id, origin: origin, p_id: primary_id)
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

  	"Sorry, I couldn't get the song title #{EMOJI[:sweat]}"
	end


  # def self.check_user(id)
  # 	user = User.find_by(telegram_id: id)
  # 	return user if user

  # 	advice = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard:[[{text: '/start'}]], one_time_keyboard: true )
  #   bot.api.send_message(chat_id: id, text: 'Try \'/start\' first!', reply_markup: advice)
  # end
end