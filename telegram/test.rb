require File.expand_path('../config/environment', __dir__)
require 'telegram/bot'
require 'pry'
require 'launchy'
require 'uri'
require 'net/http'
require 'json'

binding.pry
a.each_with_object({}).with_index {|val_hash,i| p val_hash[1][i] = val_hash[0]}

a.each_with_index.with_object({}) {|(val, i), hash| hash[i] = val}

puts 'end'
