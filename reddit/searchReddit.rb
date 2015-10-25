require 'redditkit'

#Create the reddit client and the scheduler
client = RedditKit::Client.new 'reddit_username', 'reddit_password'

#Reddit rate limiter at 0.5 requests/second. (1 per 2 seconds)
def getReoccurence()
	print "How often do you want to check for a new thread? (Min. 5s) \n"
	print "In seconds: "
	s = $stdin.gets.chomp.to_i
	if s < 5
		#set minimum to 5 seconds, to cleanly avoid the rate limiter.
		#speculated that it's done by IP, so higher the better when
		#sharing internet
		return 5
	else
		return s
	end
end

#get the keyword to query for
def getSearchTerms()
	print "What would you like to search on Reddit? \n"
	print "Search for any recent keywords: 'Huskies' \n"
	print "Search: "
	s = $stdin.gets.chomp
	return s
end


searchTerm = getSearchTerms() #ask what you want to search
speed = getReoccurence() #how often to query, in seconds

#create a function to get the latest reddit thread id
def getLatestThreadID(client, termToSearch)
	client.search(termToSearch, options={sort: 'new'}).take(1).each do |result|
		return result
	end
end

#get the latest thread ID using the above function. used for comparison below
latestThreadID = getLatestThreadID(client, searchTerm)

#clear the terminal to make it look clean
system("clear")
#set the amount of latest threads to pull, before querying every # of seconds
amountOfLatestThreads = 5

#get the # most recent threads regarding bitpay in the bitcoin subreddit. set above
client.search(searchTerm, options={sort: 'new'}).take(amountOfLatestThreads).each do |result|
	puts "Thread author: " + result.author + "\n"
	puts "Thread title: " + result.title + "\n"
	puts "Thread link: " + result.permalink + "\n"
	puts "\n"
 end

timeWhenLatestThread = Time.now;
print "The #{amountOfLatestThreads} latest threads as of #{timeWhenLatestThread}: \n"
print "Checking for new threads for the '#{searchTerm}' keyword every #{speed} seconds. Will update when one arrives. \n"

 while 1
	n = Time.now
	client.search(searchTerm, options={sort: 'new'}).take(1).each do |result|
		if result != latestThreadID
			latestThreadID = result
			print "New thread at #{n}:\n"
			puts "Thread author: " + result.author + "\n"
			puts "Thread title: " + result.title + "\n"
			puts "Thread link: " + result.permalink + "\n"
			puts "\n"
			print "The #{amountOfLatestThreads} latest threads as of #{timeWhenLatestThread}: \n"
			print "Checking for new threads for '#{searchTerm}' every #{speed} seconds. Will update when one arrives. \n"
			puts "\n"
		end
	end
	sleep(speed)
end
