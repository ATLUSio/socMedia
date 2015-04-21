##Required Gems below.
##Comment out any gems that are not needed.
##Note: Slack notifications automatically commented out.

##Require Twitter Gem for Twitter API handling
require 'twitter'

##Configure the client. Done through apps.twitter.com.
##Add an app to your account, and you should be provided with the creds below
client = Twitter::REST::Client.new do |config|
  config.consumer_key = "your_keys_here"
  config.consumer_secret = "your_keys_here"
  config.access_token = "######-your_keys_here"
  config.access_token_secret = "your_keys_here"
end

##Require and configure Rufus's scheduler gem, for cronjob handling
require 'rufus-scheduler'
scheduleSearch = Rufus::Scheduler.new

##Require the slack notifier gem, for easy push notifications to Slack
##Link to create webhook: https://api.slack.com/applications/new
require 'slack-notifier'
slacker = Slack::Notifier.new "your_webhook_here"

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
searchTerm = getSearchTerms

##Gets the URL of the tweet to use in comparison for newer tweets
def getLatestTweetID(client, termToSearch)
  client.search(termToSearch).take(1).each do |tweet|
    return tweet.uri
  end
end

##Get the latest tweet ID using the above fx.
latestTweetID = getLatestTweetID(client, searchTerm)
print "Latest tweet ID: #{latestTweetID} \n"

##create a blacklist for twitter users we wish to filter out. useful for bots
blacklist = []

##create an array of strings/tweets to compare to.
arrayCompare = []

##uses arrayCompare to detect and see if a tweet is at least 50% identical. Returns True or False.
##if returned True, the tweet is similar and it should not be posted. If false, it is unique and should be posted
def findMatch(arrayCompare, newTweet)
  ##create 'c' variable for math below
  c = 0
  ##create i2 to return to the arrayCompare method
  i2 = 0
  ##create our return variable. defaults to false at end of this method. Q for '?' since ruby doesn't allow ?s in vars
  similarQ = false
  ##take each item from an array (has to be array) and do some'thing'
  arrayCompare.each do |thing|
    ##remove the hashtags, since that will cause an unnecessary shift in the the string's character index
    thing.delete! '#'
    ##set thing (one array index) to the length of the new tweet.
    thing = thing[0...newTweet.length] #if thing.length > newTweet.length
    ##while the value of 'c', the variable we chose for 'C'omparison, is less then 50% continue
    ##searching for matches. Additionally, set it to not continue if i2 is greater than the length of the new tweet
    while c < 0.5 and i2 < newTweet.length do
      ##every time that this cycles, reset our 'I'ncrement 'M'atcher to 0 and resets your 'I'ncrement
      ##to 0 plus your '2'ndary 'I'ncrement, which increments by 1 through each 'thing'
      im = 0
      i = 0 + i2
      thing.each_char do |thing2|
        ##gets each character and compares the corresponding character of newTweet, indicated by 'i'
        if thing2 == newTweet[i]
          ##increment both i and im by 1, since it was cycled through 1 time and there was a match
          i += 1
          im += 1
        else
          ##simply increment i by one, don't increment im since no match
          i += 1
        end
      end
      ##calculate C to see if it is at least 50% (0.5)
      c = (im.fdiv(i-i2))
      ##increment i2, to shift the character detector
      i2 += 1
    end
    if c > 0.5 
    ##return i2, since at netweet[i2] 
      similarQ = true
      return similarQ
    else
      i2 = 0
    end
  end
  ##if it gets to here, it'll return false since it wasn't made to be true above
  return similarQ
end

##Return latest tweets using the client and the quantity of tweets
def latestTweets(client, numberOfLatestTweets, termToSearch)
  client.search(termToSearch).take(numberOfLatestTweets).each do |tweet|
    print "ID: " + tweet.to_s + "\n"
    puts tweet.user.screen_name
    puts tweet.text
    puts tweet.uri
  end
end

##function that will do a .each check on each of the items in the blacklist,
##to make sure the tweeters are not one of the ones in the blacklist.
def tweetBlacklist(blacklistCheck, userCheck)
  ##starts off false
  blacklisted = false
  ##checks the blacklist passed as the first item in this method. for each index, do 'check,'
  ##which checks if the userCheck, or the second item passed in the array is on the blacklist
  blacklistCheck.each do |check|
    if check == userCheck
      ##set blacklisted to true if it was a match
      blacklisted = true
    end
  end
  if blacklisted == true
    ##if true, return true, so we can do if method == true... do this
    return true
  else
    ##if not true, then return false
    return false
  end
end

def seperator(quantity)
  ##for formatting
  quantity.times do
    print "-"
  end
  print "\n"
end

##clear screen (formatting) and get the latest # of tweets using the above fx
system ("clear")
timeWhenLatestTweets = Time.now; ##prints time
print "The #{quantity} latest tweets as of #{timeWhenLatestTweets}: \n" ##prints tweets
latestTweets(client, quantity, searchTerm)

print "\n"
print "Checking for new tweets '#{searchTerm}' every #{speed} seconds. Will update when a new one arrives. \n"

##create our blocked and posted counters
totalBlocked = 0
totalPosted = 0
##Set a schedule to update only if latestTweetID is not equal to the latest tweet
scheduleSearch.every speed, :first => :now do
  n = Time.now; ##set n to current time
  client.search(searchTerm).take(1).each do |tweet|
    ##if the latest tweet is not equal to latestTweetID and if the user's screen_name is on the
    ##blacklist, print that we found a new tweet, increment blocked, set to new uri
    if tweet.uri != latestTweetID and tweetBlacklist(blacklist, tweet.user.screen_name) == true
      totalBlocked += 1
      seperator(20)
      print "New tweet found, but user on blacklist. \n"
      print "Total blocked: #{totalBlocked} \n"
      print "Block ratio: " + ((totalBlocked.fdiv(totalPosted+totalBlocked))*100).to_s + " \n"
      seperator(20)
      latestTweetID = tweet.uri
    end
    ##if tweet.text is a match to a previous tweet in the array, do not include it 
    if tweet.uri != latestTweetID and findMatch(arrayCompare, tweet.text) == true
      totalBlocked += 1
      seperator(20)
      print "New tweet found, but it was nearly identical to one in the \"compareArray\" array. \n"
      print "Total blocked: #{totalBlocked} \n"
      print "Block ratio: " + ((totalBlocked.fdiv(totalPosted+totalBlocked))*100).to_s + " \n"
      seperator(20)
      latestTweetID = tweet.uri
    end
    ##if it passes all checks, print it and slack it
    if tweet.uri != latestTweetID and tweetBlacklist(blacklist, tweet.user.screen_name) == false and findMatch(arrayCompare, tweet.text) == false
      slacker.ping tweet.uri.to_s ##uncomment if you would like to post to Slack
      totalPosted +=1 
      seperator(20)
      print "New tweet at #{n}: \n"
      latestTweetID = tweet.uri #set latestTweetID to the current tweet, since the current tweet is the most recent
      puts tweet.text
      puts tweet.uri
      print "Total posted: #{totalPosted} \n"
      print "Block ratio: " + ((totalBlocked.fdiv(totalPosted+totalBlocked))*100).to_s + " \n"
      print "Checking for new tweets '#{searchTerm}' every #{speed} seconds. Will update when a new one arrives.\n"
      seperator(20)
    end
  end
end

scheduleSearch.join