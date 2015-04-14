#Required gems 
require 'Twitter' #twitter gem
require 'rufus-scheduler' #cronjob gem

#Configure the client. Done through apps.twitter.com

client = Twitter::REST::Client.new do |config|
	config.consumer_key = "keys_here"
	config.consumer_secret = "keys_here"
	config.access_token = "keys_here"
	config.access_token_secret = "keys_here"
end

#Configure the rescheduler
scheduleSearch = Rufus::Scheduler.new

#global variables
#type = String.new #set type a global variable so we can write to it in methods

#Gets the type of repeated time, whether seconds, minutes, hours, or days.
#Anything higher than days is not coded for
def getType() 
	print "What type of time: \n 1 - Seconds \n 2 - Minutes \n 3 - Hours \n 4 - Days \n"
	type = gets.chomp
end

#Determines how many tweets we want to pull. 
def getTweetQuantity()
	print "How many tweets would you like to limit your search to (5 recommended): "
	return $stdin.gets.chomp.to_i
end

#How often do you want to cycle through the option? All translated into seconds
#Uses a string as an input and some math to determine how many seconds
def getReoccurence(type)
	if type == "1"
		print "How many seconds to repeat job? \n"
		#Twitter's rate limiter is 180 searches every 15 minutes, or 1 search every
		#5 seconds. e.g. If you have two searches running side by side, you can only
		#perform 1 search every 10 seconds. 
		print "Recommended >30, otherwise you will hit Twitter's rate limiter: "
			defaultSeconds = 30
			secondsChosen = $stdin.gets.chomp.to_i
			if secondsChosen < 30
				print "#{secondsChosen} seconds is too quick. Default value #{defaultSeconds} chosen. \n"
				return 30
			else
				return secondsChosen
			end
	elsif type == "2"
		print "How many minutes? "
		t = $stdin.gets.chomp.to_i
		return t*60
	elsif type == "3"
		print "How many hours? "
		t = $stdin.gets.chomp.to_i
		return t*60*60
	elsif type == "4"
		print "How many days? "
		t = $stdin.gets.chomp.to_i
		return t*60*60*24
	else
		puts "Either input was misspelled or the code doesn't support that time frame."
		puts "Setting time to 60 seconds."
		return 60
	end 
end

def getSearchTerms()
	print "What would you like to search on Twitter? \n"
	print "Search to someone: 'to:atlusio' \n"
	print "Search for recent hashtags: '#PlayGameOfThrones' \n"
	print "Search for any recent keywords: 'Huskies' \n"
	print "Include '-rt' for no retweets: 'Huskies -rt' \n"
	print "Search: "
	s = $stdin.gets.chomp
	return s 
end


quantity = getTweetQuantity() #Ask how many tweets one will want
type = getType() #Ask what type of time, converts to seconds
speed = getReoccurence(type) #Ask how often, the type of time. Use 'type' as an input
searchTerm = getSearchTerms()

#specifically get the latestTweetID, to use in comparison
def getLatestTweetID(client)
	client.search("to:bitpay").take(1).each do |tweet|
		return tweet
	end
end

#get the latest tweet ID using the above fx
latestTweetID = getLatestTweetID(client)

#Return latest tweets using the client and the quantity of tweets
def latestTweets(client, numberOfLatestTweets, termToSearch)
	client.search(termToSearch).take(numberOfLatestTweets).each do |tweet|
		puts tweet.text
		puts tweet.uri
	end
end

#get the latest # of tweets using the above fx
system ("clear")
timeWhenLatestTweets = Time.now;
amountOfLatestTweets = quantity
print "The #{amountOfLatestTweets} latest tweets as of #{timeWhenLatestTweets}: \n"
latestTweets(client, amountOfLatestTweets, searchTerm)

print "\n"
print "Checking for new tweets '#{searchTerm}' every #{speed} seconds. Will update when a new one arrives. \n"

#Set a schedule to update only if latestTweetID is not equal to the latest tweet
scheduleSearch.every speed, :first => :now do
  n = Time.now; #set n to current time
  client.search(searchTerm).take(1).each do |tweet|
  	#if the latest tweet is not equal to 
  	if tweet != latestTweetID
  		print "New tweet at #{n}: \n"
  		latestTweetID = tweet #set latestTweetID to the current tweet, since the current tweet is the most recent
  		puts tweet.text
  		puts tweet.uri
  		print "Checking for new tweets '#{searchTerm}' every #{speed} seconds. Will update when a new one arrives.\n"
  		print "\n"
  	end
  end
end

scheduleSearch.join