require 'twitter'
require 'similar_text'

client = Twitter::REST::Client.new do |config|
	config.consumer_key = "key"
	config.consumer_secret = "secret"
	config.access_token = "#######-token"
	config.access_token_secret = "token_secret"
end
#Easy push notifications to Slack
##Link to create webhook: https://api.slack.com/applications/new
#require 'slack-notifier'
#slacker = Slack::Notifier.new "webhook_here"

##Gets the type of repeated time, whether seconds, minutes, hours, or days.
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
##create a blacklist for twitter users we wish to filter out. useful for bots
blacklist = []
##create an array to add tweets to, so we do not get identical tweets.
arrayCompare = []

##detects to see if a tweet is at least 50% identical. Returns True or False.
##if returned True, the tweet is similar and it should not be posted. If false, it is unique and should be posted
def findMatch(arrayCompare, newTweet)
	arrayCompare.each do |thing| #for each item in arrayCompare, do 'thing'
		c = thing.similar(newTweet) #set c equal to the similarity value (0-100) of 'thing' and 'newTweet'
		if c > 50 #if the value of c is greater than 50, or more than 50% similar
			return true #return true, that it's similar
		end
	end
	return false #if 'thing' is iterated through the entire arrayCompare and there is no match... return false... not similar
end

#Return latest tweets using the client and the quantity of tweets
##pass in the client to search, the amount of tweets we want, the term, and the array so we can not immediately post the returned tweets
def latestTweets(client, numberOfLatestTweets, termToSearch, arrayCompare)
	client.search(termToSearch).take(numberOfLatestTweets).each do |tweet| #search for #{searchTerms} quantity times, and do 'tweet'
		print "ID: " + tweet.to_s + "\n" #show us all the tweets
		puts tweet.user.screen_name #show us their username
		puts tweet.text #show us their text
		puts tweet.uri #show us their link
		arrayCompare << tweet.text #add them all to the compare array so we don't post 'quantity' amount of tweets for no reason
	end
end

#function that will do a .each check on each of the items in the blacklist,
#to make sure the tweeters are not one of the ones in the blacklist.
def tweetBlacklist(blacklistCheck, userCheck)
	blacklisted = false #initially set blacklist to false
	blacklistCheck.each do |check| #do 'check' for each item of blacklist
		if check == userCheck #if check is equal to userCheck, which is passed in during evaluation at the bottom...
			blacklisted = true # set blacklist to true
		end
	end
	if blacklisted == true #if blacklist is set to true
		return true #return true, the user is on blacklist
	else
		return false #if it's not set to true, then return false. user is not on blacklist.
	end
end

def seperator(quantity)
	quantity.times do
		print "-"
	end
	print "\n"
end

#get the latest # of tweets using the above fx
system ("clear")
timeWhenLatestTweets = Time.now;
amountOfLatestTweets = quantity
print "The #{amountOfLatestTweets} latest tweets as of #{timeWhenLatestTweets}: \n"
latestTweets(client, amountOfLatestTweets, searchTerm, arrayCompare)

print "\n"
print "Checking for new tweets '#{searchTerm}' every #{speed} seconds. Will update when a new one arrives. \n"

totalBlocked = 0
totalPosted = 0
totalTweets = 0

#Set a schedule to update only if latestTweetID is not equal to the latest tweet
while 1
  	n = Time.now; #set n to current time
  	client.search(searchTerm).take(quantity).each do |tweet|
  		##if the latest tweet is not equal to latestTweetID and if the user's screen_name is on the
  		##blacklist, print that we found a new tweet, increment blocked, set to new uri
  		tweetCompare = tweet.text #newTweet
  		tweetUser = tweet.user.screen_name #user's screen name for blacklist comparison
  		varFindMatch = findMatch(arrayCompare, tweetCompare) #find if there are any matches
  		varBlacklist = tweetBlacklist(blacklist, tweetUser) #find if any users are blacklisted

  		totalTweets += 1
  		#if it passes the two checks, post the tweet
		if varFindMatch == false and varBlacklist == false
			slacker.ping (tweet.uri).to_s #post to slack
			arrayCompare << tweetCompare #add the tweet to the array, since it's unique
			totalPosted += 1 #increment post count
			seperator(20) #seperate for easy viewing
			print "New tweet at #{n}: \n" #let us know we have a tweet
			puts tweet.text #shows the text of the tweet
  			puts tweet.uri #shows the URL of the tweet
  			print "Total posted: #{totalPosted} \n" #lets us know how many tweets were posted
  			print "Block ratio: " + ((totalBlocked.fdiv(totalPosted+totalBlocked))*100).to_s + "%\n" #let us know what % were blocked
 	 		print "Checking for new tweets '#{searchTerm}' every #{speed} seconds. Will update when a new one arrives.\n"
  		#if it fails the above test, check to see which of the bottom two it failed on
  		#run blacklist first, since we want to omit all those we do not want to see first. if it's not false, it has to be true.
  		elsif varBlacklist == true
  			totalBlocked += 1 #increment blocked count
  			seperator(20) #seperate for easy viewing
  			print "Tweet blocked because user on blacklist. \n" #let us know the outcome of this tweet
  			print "Total Blocked: " + ((totalBlocked.fdiv(totalTweets))*100).to_s + "%\n" #block %
  		#if the user is not blacklisted, see if this tweet is a non-unique tweet. if it's not false, it has to be true.
 	 	elsif varFindMatch == true
  			totalBlocked += 1 #increment blocked count
  			seperator(20) #seperate for easy viewing
  			print "Tweet blocked because it was nearly identical to one in the \"compareArray\" array. \n" #tell us why it was blocked
  			print "Total Blocked: " + ((totalBlocked.fdiv(totalTweets))*100).to_s + "%\n" #block %
  		end
  	end
		sleep(speed)
end
