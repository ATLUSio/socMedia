# socMedia

|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||

||||||||||||||| Social Media Tools Using Ruby

|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||


|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||

||||||||||||||| Authentication

|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||

Twitter:
- Log into your Twitter account
- Create your keys on "https://apps.twitter.com/"
- Copy and paste your keys into the top of tweetSearch.rb
 
Reddit:
- Add your username and password at the top of redditSearch.rb

Slack:
- Create webhook on: https://api.slack.com/applications/new
- Add the webhook to the 'slacker' instantiation

|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||

||||||||||||||| Installing dependencies

|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||

- open terminal
- run 'sudo gem install twitter' (enter password)
- run 'sudo gem install redditkit' (enter password)
- run 'sudo gem install rufus-scheduler' (enter password)
- run 'sudo gem install slack-notifier' (enter password) < If you want Slack notifications
- run 'sudo gem install similar_text' (enter password)


|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||

||||||||||||||| Running the Scripts

|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||

Running Twitter Search:
- open terminal
- cd into the directory ~/socMedia/twitter/
- run 'ruby tweetSearch.rb' and follow instructions

Running Reddit Search:
- open terminal
- cd into the directory ~/socMedia/reddit/
- run 'ruby redditSearch.rb' and follow instructions

|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
