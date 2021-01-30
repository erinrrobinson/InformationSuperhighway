#!/usr/bin/env python
# -*- coding: utf-8 -*-

import markovify
import threading
from random import randint
from pythonosc import udp_client
import argparse
import random
import tweepy
from datetime import datetime, timedelta
import re


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--ip", default="127.0.0.1",
                        help="The ip of the OSC server")
    parser.add_argument("--port2", default=12000,
                        help="The port the OSC server is listening on")
    parser.add_argument("--port", type=int, default=7400,
                        help="The port the OSC server is listening on")
    args = parser.parse_args()

client = udp_client.SimpleUDPClient(args.ip, args.port)
clients = udp_client.SimpleUDPClient(args.ip, args.port2)

# Access tokens
ACCESS_TOKEN = "ACCESS_TOKEN"
ACCESS_TOKEN_SECRET = "ACCESS_TOKEN_SECRET"
CONSUMER_KEY = "CONSUMER_KEY"
CONSUMER_SECRET = "CONSUMER_SECRET"

auth = tweepy.OAuthHandler(CONSUMER_KEY, CONSUMER_SECRET)
auth.set_access_token(ACCESS_TOKEN, ACCESS_TOKEN_SECRET)
api = tweepy.API(auth, wait_on_rate_limit=True)


def usersearchwords():
    searchWord = open("searchWord", "w")

    for tweet in tweepy.Cursor(api.search, q='@serena_speaks' + " -filter:retweets").items(20):
        print(tweet.text)
        list = tweet.text
        strTweet = ''.join(list)
        searchWord.write(strTweet)

    searchWord.close()
    search = open('choice', 'w')

    with open("searchWord") as word_file:
        words = word_file.read()
        regex = re.sub('the', '', words)
        regex6 = re.sub("'", "", regex)
        regex3 = re.sub(r'@\w+', '', regex6)
        regex4 = re.sub(r'\w+…\s?', '', regex3)
        regex5 = re.sub(r'[^\w\s]', '', regex4)
        regex6 = re.sub(
            '(he|down|good|need|label|cause|come|talk|having|much|gotta|right|Your|meet|thing|turn|wait|call|doing|Again|again|whos|haha|hahaha|tell|been|anor|What|With|hahahaha|were|about|looks|really|long|short|just|name|with|word|lost|should|shouldnt|coming|going|show|self|before|from|must|mustnt|after|taking|will|wont|she|they|them|there|went|when|where|want|this|that|your|Youre|arent|werent|wasnt|know|youve|yourself|myself|always|never|more|less|like|what|same|have|else)',
            '', regex5)
        print(words)
        search.write(regex6)

    search.close()


def builddatabase():
    with open('choice') as choose_word:
        word = choose_word.read().split()
        words = [word.rstrip() for word in word if len(word) > 3]

    listStrings = [random.choice(words), random.choice(words), random.choice(words)]
    print(listStrings)
    timeinterval = 2

    file = open("database", "w")

    for string in listStrings:
        start = datetime.now()
        for tweet in tweepy.Cursor(api.search, q=string + " -filter:retweets", count=100,
                                   lang="en",
                                   since="2018-06-01").items():

            list = tweet.text
            strTweet = ''.join(list)
            print(strTweet)
            file.write(strTweet)
            # Break condition
            if datetime.now() - start > timedelta(seconds=timeinterval):
                break

    file.close()


def markov():

    threading.Timer(15.0, markov).start()
    with open("database") as corpus_file:
        text = corpus_file.read()
    regex = re.sub(r'\w+…\s?', '', text)
    regexs = re.sub('&', '', regex)
    regex2 = re.sub('\.\.\.', '', regexs)
    regex3 = re.sub('#', '', regex2)
    regex4 = re.sub('(RT|"|amp;)', '', regex3)
    URLless_string = re.sub(r'\w+:\/{2}[\d\w-]+(\.[\d\w-]+)*(?:(?:\/[^\s/]*))*', '', regex4)
    regex5 = re.sub(r'@\w+', '', URLless_string)
    text_model = markovify.Text(regex5)
    for i in range(1):
        markovtweet = text_model.make_short_sentence(randint(50, 120))
        client.send_message("/markov", markovtweet)
        api2 = tweepy.API(auth)
        api2.update_status(markovtweet)
        print(markovtweet)


usersearchwords()
builddatabase()
markov()





