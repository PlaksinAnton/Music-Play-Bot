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

	def init_values(message)
		@id = message.from.id
		@user = User.find_by(telegram_id: @id) || User.create(name: message.from.username, telegram_id: id, step: 0)
	end

	def do_the_bot_thing(message)
		# binding.pry
		init_values(message)

    case message
    when Telegram::Bot::Types::Message

      answer_to_user(message)

    when Telegram::Bot::Types::CallbackQuery

      react_to_button(message)
    
    end
	end

  def init_user(id, username)
  	User.find_by(telegram_id: id) || User.create(name: username, telegram_id: id, step: 0)
  end

  def answer_to_user(message)
  	return handle_start(@id,  @user.name) if message.text	== '/start'

  	return send_history_message(@id, @user) if message.text	== '/history'

  	url = message.text[/(https:\/\/(?:www\.)?youtu\.?be(?:\.com)?.*?)(?:\s|$)/, 1]
  	return error_message(@id) unless url

  	track_hash = { url: url }
    track_hash[:name] = get_track_name(get_html(track_hash))
    track = Track.find_by(url: track_hash[:url]) || Track.create(track_hash)

    send_play_message(@id, track)
  end

  def handle_start(id, username)
  	if User.find_by(telegram_id: id)
  		@bot.api.send_message(chat_id: id, text: "\xF0\x9F\x91\x80")
  	else
  		User.create(name: username, telegram_id: id, step: 0)
  		@bot.api.send_message(chat_id: id, text: 'You can send me youtube videos to play it on the TV.')
  	end
  	true
  end

  def error_message(id)
    @bot.api.send_message(chat_id: id, text: "Sorry, I don`t understand you \xF0\x9F\x98\xB3")
    false
  end

  def send_play_message(id, track)
  	keyboard = [[
            Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Play now', callback_data: make_callback_json('play', track.id)),
            Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Add to queue', callback_data: make_callback_json('queue', track.id)),
            ]]
  	keyboard_markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: keyboard)
  	@bot.api.send_message(chat_id: id, text: track.name, reply_markup: keyboard_markup)
  	true
  end

  def send_history_message(id, user)
  	history_markup = create_history_markup
  	bot_message = @bot.api.send_message(chat_id: id, text: 'Recently played tracks:', reply_markup: history_markup)
  	user.update(history_id: bot_message.dig('result', 'message_id'))
  end

  def update_history_message(id, message_id)
  	history_markup = create_history_markup
  	@bot.api.edit_message_text(chat_id: id, message_id: message_id, text: 'Recently played tracks:', reply_markup: history_markup)
  end

  def create_history_markup
  	keyboard = PlayedTrack.order(created_at: :desc).limit(10).map.with_index do |t, i|
  		name_in_button = t.track.name.size > 50 ? t.track.name[..50]+'..' : t.track.name
  		button_text = "#{name_in_button} - #{t.user.name}"
  		[Telegram::Bot::Types::InlineKeyboardButton.new(text: button_text, callback_data: make_callback_json('play', t.track.id))]
  	end
  	Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: keyboard)
  end

  def react_to_button(message)
  	json = JSON(message.data, symbolize_names: true)

  	case json[:type]
		when 'play'
    	@bot.api.send_message(chat_id: @id, text: 'запусптил видос')
      # Launchy.open(Track.find(json[:play]).url)
      PlayedTrack.create(track_id: json[:track_id], user_id: @user.id)
      update_history_message(@id, @user.history_id)
    when 'queue'
      @bot.api.send_message(chat_id: @id, text: 'You send queue')
    end
  end

  def make_callback_json(type, track_id)
  	JSON(type: type, track_id: track_id)
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