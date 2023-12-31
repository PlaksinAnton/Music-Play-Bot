# README

## Overview
If your TV is connected to the computer it is convenient to be able to play any clip in a couple button presses on your phone.  

This is a telegram bot that allows you to play (and manage) youtube videos on the computer where the bot is running by simply sending a URL to it.  

This bot is made on Linux using Ruby on Rails.  

## Steps to get the telegram bot up and running (for Linux):

* **[Install Ruby (with rbenv)](https://github.com/rbenv/rbenv) Version 3.2.2**  

* **Clone the repository**
	Choose the folder where you want the bot and use git clone to get this repository on your computer  
	$```git clone https://github.com/PlaksinAnton/Music-Play-Bot.git```  
	Get in it  
	$```cd Music-Play-Bot```  

* **Install all ruby dependencies**  
	$```bundle install```  

* **Database creation**  
	$```RAILS_ENV=production rake db:migrate```  
	$```RAILS_ENV=production DISABLE_DATABASE_ENVIRONMENT_CHECK=1 rake db:reset```- use it to clear-up db  

* **Telegram bot creation**  
	Go to [BotFather](https://telegram.me/BotFather) and create a new bot with ```/newbot``` command (then follow the instructions).  
	Also it is useful to set menu for available commands for new bot, so not to type them manually later.  
	Use ```/setcommands``` to add the following commands to the created bot  
	```
	saved - See all currently saved tracks  
	history - See last played tracks  
	```
	> [!NOTE]  
	> You can change description, if you like 

* **Configuration:**  
	Back to your terminal:  
	$```bundle exec figaro install``` - creates config/application.yaml file (also adds it to .gitignore)  
	Isert token that you've got from the BotFather to the config file  
	$```echo "TOKEN: $YOUR_TOKEN" >> config/application.yml```  

* **Run the bot**  
	To run the bot you can use the following command  
	$```RAILS_ENV=production ruby telegram/main.rb```  
	But it's better to create systemd service if you want it always online  
	$```sudo touch /etc/systemd/system/music-play-bot.service```  
	Now open music-play-bot.service file and configure it:
  	```
	[Unit]  
	Description=Telegram bot for launching videos on this computer  
	  
	[Service]  
	User=<$USER or root>  
	WorkingDirectory=<full path to project folder>  
	Environment="RAILS_ENV=production"  
	ExecStart=<path to ruby interpreter> <full path to project folder>/telegram/main.rb  
	After=network-online.target  
	Wants=network-online.target  
	Restart=always  
	RestartSec=3  
	  
	[Install]  
	WantedBy=multi-user.target  
	```
	> [!NOTE]  
	> The user must be the same user that installed ruby  

	> [!NOTE]
	> Path to the ruby interpreter can be found by $```which ruby```. Most likely it is /home/$USER/.rbenv/shims/ruby  


	Reload the service files, enable your service on every reboot and start it  
	$```sudo systemctl daemon-reload```  
	$```sudo systemctl enable music-play-bot.service --now```  

* **Well done!**

## Functionality
The bot has two commands available  

* /history - shows last played videos.  
* /saved   - shows list of saved videos. Clip get removed from the saved list as soon as it is selected.  

To save or play new video just send a youtube URL to the bot and choose the option.
