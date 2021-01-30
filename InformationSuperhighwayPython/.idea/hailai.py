import markovify
import tweepy


consumer_key = "rMzP9OZNKpJ90MahSS9Ow22JX"
consumer_secret = "8regJBSep2Pk2iyNDBB7ig7uNfUuvYl6dviAlmvErZjDR9ALIj"
access_token = "994512410395410432-T02SxjHiXP4z8xTGNx9Aar50f5iChtW"
access_token_secret = "nyKWWWEytJ7NOrjEp4juAZYTYUqjaerIHE4GCnRCe2F82"

auth = tweepy.OAuthHandler(consumer_key, consumer_secret)
auth.set_access_token(access_token, access_token_secret)
api = tweepy.API(auth)

with open("corpus.txt") as corpus_file:
	corpus = corpus_file.read()

model = markovify.Text(corpus)
