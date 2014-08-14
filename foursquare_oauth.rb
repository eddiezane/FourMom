#!/usr/bin/env ruby

require 'net/http'
require 'json'

puts 'This will authenticate you with your foursquare app!'
puts 'Please enter the following from you apps info page'
puts

puts 'Client id?'
client_id = gets.chomp
puts

puts 'Client secret?'
client_secret = gets.chomp
puts

puts 'Callback url?'
callback_url = gets.chomp
puts

url = "https://foursquare.com/oauth2/authenticate?client_id=#{client_id}&response_type=code&redirect_uri=#{callback_url}"
puts 'Visit this url in your browser, click allow, and copy the code from the redirected url'
puts url
puts

puts 'Code?'
code = gets.chomp
puts

uri = URI.parse('https://foursquare.com/oauth2/access_token')
params = {client_id: client_id, client_secret: client_secret, grant_type: 'authorization_code', redirect_uri: callback_url, code: code}
uri.query = URI.encode_www_form(params)
token = JSON.parse(Net::HTTP.get(uri))['access_token']
puts "You have authenticated! Token: #{token}"
