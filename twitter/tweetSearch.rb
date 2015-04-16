##Required Gems below.
##Comment out any gems that are not needed.
##Note: Slack notifications automatically commented out.

##Require Twitter Gem for Twitter API handling
require 'twitter'

##Require and configure Rufus's scheduler gem, for cronjob handling
require 'rufus-scheduler'
scheduleSearch = Rufus::Scheduler.new

##Require the slack notifier gem, for easy push notifications to Slack
##Link to create webhook: https://api.slack.com/applications/new
#require 'slack-notifier'
#slacker = Slack::Notifier.new "full_webhook_URL_here"

##Configure the client. Done through apps.twitter.com.
##Add an app to your account, and you should be provided with the creds below
client = Twitter::REST::Client.new do |config|
	config.consumer_key = "api_creds_here"
	config.consumer_secret = "api_creds_here"
	config.access_token = "api_creds_here"
	config.access_token_secret = "api_creds_here"
end

##Gets the type of repeated time, whether seconds, minutes, hours, or days.
##Anything higher than days is not coded for
def getType() 
	print "What type of time: \n 1 - Seconds \n 2 - Minutes \n 3 - Hours \n 4 - Days \n"
	type = gets.chomp
end

##Determines how many tweets we want to initially pull. 
def getTweetQuantity()
	print "How many tweets would you like to limit your search to (5 recommended): "
	return $stdin.gets.chomp.to_i
end

##How often do you want to cycle through the option? All translated into seconds
##Uses a string as an input and some math to determine how many seconds
def getReoccurence(type)
	if type == "1"
		print "How many seconds to repeat job? \n"
		##Twitter's rate limiter is 180 searches every 15 minutes, or 1 search every
		##5 seconds. e.g. If you have two searches running side by side, you can only
		##perform 1 search every 10 seconds. 
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

##Gets the term to search for. 
def getSearchTerms()
	print "What would you like to search on Twitter? \n"
	print "Search to someone: 'to:atlusio' \n"
	print "Search for recent hashtags: '#TaylorSwift' \n"
	print "Search for any recent keywords: 'TaylorSwift' \n"
	print "Include '-rt' for no retweets: 'TaylorSwift -rt' \n"
	print "Search: "
	s = $stdin.gets.chomp
	return s 
end

##Ask how many tweets we will want
quantity = getTweetQuantity() 

##Ask what type of time, converts to seconds
type = getType() 

##Ask how often, the type of time. Use 'type' from above as the input
speed = getReoccurence(type) 

##Ask for what terms we want to search for
searchTerm = getSearchTerms()

##Gets the URL of the tweet to use in comparison for newer tweets
def getLatestTweetID(client, termToSearch)
	client.search(termToSearch).take(1).each do |tweet|
		return tweet.uri
	end
end

##Get the latest tweet ID using the above fx.
latestTweetID = getLatestTweetID(client, searchTerm)
print "Latest tweet ID: #{latestTweetID} \n"

#create a blacklist for twitter users we wish to filter out
#useful for bots
blacklist = []

#Return latest tweets using the client and the quantity of tweets
def latestTweets(client, numberOfLatestTweets, termToSearch)
	client.search(termToSearch).take(numberOfLatestTweets).each do |tweet|
		print "ID: " + tweet.to_s + "\n"
		puts tweet.user.screen_name
		puts tweet.text
		puts tweet.uri
	end
end

#function that will do a .each check on each of the items in the blacklist,
#to make sure the tweeters are not one of the ones in the blacklist.
def tweetBlacklist(blacklistCheck, userCheck)
	blacklisted = false
	blacklistCheck.each do |check|
		if check == userCheck
			blacklisted = true
		end
	end
	if blacklisted == true
		return true
	else
		return false
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
  	##if the latest tweet is not equal to latestTweetID and if the user's screen_name is on the
  	##blacklist, print that we found a new tweet and the tweet's information. Reiterate speed.
  	if tweet.uri != latestTweetID and tweetBlacklist(blacklist, tweet.user.screen_name) == false
  		#slacker.ping tweet.uri.to_s ##uncomment if you would like to post to Slack
  		print "New tweet at #{n}: \n"
  		latestTweetID = tweet.uri #set latestTweetID to the current tweet, since the current tweet is the most recent
  		puts tweet.text
  		puts tweet.uri
  		print "Checking for new tweets '#{searchTerm}' every #{speed} seconds. Will update when a new one arrives.\n"
  		print "\n"
  	end
  end
end

scheduleSearch.join