require 'rubygems'
require 'sinatra'

set :sessions, true


get '/' do
	"Hey there, diddy"
end

get '/template' do
	erb :mytemplate
end

get '/nested_template' do
	erb :"/users/profile"
end

get '/nothere' do
	redirect '/'
end

get '/form' do
	erb :form
end

post '/myaction' do
puts params['username']
	end