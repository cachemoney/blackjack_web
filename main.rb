require 'rubygems'
require 'sinatra'
# require 'pry'

set :sessions, true
BLACKJACK_AMT = 21
DEALER_MIN_HIT = 17
INITIAL_POT = 100
BJ_MULT = 1.5

helpers do
	def calculate_total(cards)
		arr = cards.map{|element| element[1]}

		total = 0
		arr.each do |a|
			if a == 'A'
				total += 11
			else
				total += a.to_i == 0 ? 10 : a.to_i
			end
		end
		# correct for aces
		arr.select{|element| element == "A"}.count.times do
			break if total <= BLACKJACK_AMT
			total -= 10
		end
		total
	end

	def card_image(card)
		suit =case card[0]
			when 'H' then 'hearts'
			when 'C' then 'clubs'
			when 'S' then 'spades'
			when 'D' then 'diamonds'
		end

		value = card[1]
		if ['J', 'Q', 'K', 'A'].include?(value)
			value = case card[1]
				when 'J' then 'jack'
				when 'Q' then 'queen'
				when 'K' then 'king'
				when 'A' then 'ace'
			end
		end
		"<img src='/images/cards/#{suit}_#{value}.jpg' class='card_img'>"
	end

	def winner!(msg)
		@play_again = true
		@show_hit_or_stay_buttons = false
		@success = "<strong>#{session[:username]} wins!</strong> #{msg}"
		session[:bank] += 2 * session[:wager].to_i
	end

	def loser!(msg)
		@play_again = true
		@show_hit_or_stay_buttons = false
		@error = "<strong>#{session[:username]} loses!</strong> #{msg}"
		# session[:bank] -= session[:wager].to_i
	end

	def tie!(msg)
		@play_again = true
		@show_hit_or_stay_buttons = false
		@success = "<strong>Its a tie!</strong> #{msg}"
		session[:bank] += session[:wager].to_i
	end

	def blackjack!(msg)
		@play_again = true
		@show_hit_or_stay_buttons = false
		session[:bank] += (1.5 * session[:wager].to_i).round
		@success = "<strong>#{session[:username]} wins !</strong> #{msg}"
	end

end # helpers block
before do
	@show_hit_or_stay_buttons = true
	# @play_again? = false
end

get '/' do
	if session[:username].nil?
		redirect '/new_player'
	else
 		redirect '/game'
		# session.clear
	end
end

get '/new_player' do
	session.clear
	erb :new_player
end

post '/new_player' do
	if !params[:username].empty?
		session[:username] = params['username']
		session[:wager] = params['wager']
		session[:bank] = INITIAL_POT - session[:wager].to_i
		redirect '/game'
	else
		@error = "Must input name"
		halt erb(:new_player)
	end
end

get '/game' do
	# init deck
	session[:turn] = session[:username]
	suits = ['H', 'D', 'C', 'S']
	values = ['2', '3', '4', '5', '6', '7', '8', '9','10', 'J', 'Q', 'K', 'A']
	session[:deck] = suits.product(values).shuffle!
	# deal cards
	session[:dealer_cards] = []
	session[:player_cards] = []
	session[:dealer_cards] << session[:deck].pop
	session[:player_cards] << session[:deck].pop
	session[:dealer_cards] << session[:deck].pop
	session[:player_cards] << session[:deck].pop

	player_total = calculate_total(session[:player_cards])
	if player_total == BLACKJACK_AMT
		blackjack!("#{session[:username]} hit blackjack.")
	end
		# deal player
		# deal dealer
	erb :game
end

post '/game/player/hit' do
	session[:player_cards] << session[:deck].pop
	player_total = calculate_total(session[:player_cards])
	if player_total == BLACKJACK_AMT
		winner!("#{session[:username]} hit blackjack.")
	elsif player_total > BLACKJACK_AMT
		loser!("It looks like #{session[:username]} busted at #{player_total}")
	end
	erb :game 
end

post '/game/player/stay' do
	@success = " #{session[:username]} has chosen to stay"
	@show_hit_or_stay_buttons = false
	redirect '/game/dealer'
end

get '/game/dealer' do
	session[:turn] = "dealer"
	@show_hit_or_stay_buttons = false
	dealer_total = calculate_total(session[:dealer_cards])

	if dealer_total ==	 BLACKJACK_AMT
		loser!("Dealer hit blackjack")
	elsif dealer_total > BLACKJACK_AMT
		winner!("Dealer busted #{dealer_total}")
	elsif dealer_total >= DEALER_MIN_HIT
		# dealer has 17, 18, 19 or 20
		redirect '/game/compare'
	else
		# dealer hits
		@dealer_hit_button = true
	end
	erb :game
end

post '/game/dealer/hit' do
	session[:dealer_cards] << session[:deck].pop
	redirect '/game/dealer'
end

get '/game/compare' do
	@show_hit_or_stay_buttons = false
	player_total = calculate_total(session[:player_cards])
	dealer_total = calculate_total(session[:dealer_cards])
	if player_total < dealer_total
		loser!("#{session[:username]} stayed at #{player_total}, and the dealer stayed at #{dealer_total}")
	elsif player_total > dealer_total
		winner!("#{session[:username]} stayed at #{player_total}, and the dealer stayed at #{dealer_total}")
	else
		tie!("Both #{session[:username]} and the dealer stayed at #{player_total}")
	end
	erb :game
end

get '/thankyou' do
	erb :thankyou
end

post '/process_wager' do
	session[:wager] = params['wager']
	session[:bank] -= session[:wager].to_i
	redirect '/game'
end	




